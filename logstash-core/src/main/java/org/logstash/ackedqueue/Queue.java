package org.logstash.ackedqueue;

import org.logstash.common.io.CheckpointIO;
import org.logstash.common.io.PageIO;
import org.logstash.common.io.PageIOFactory;

import java.io.Closeable;
import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.nio.file.NoSuchFileException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;


// TODO: Notes
//
// - time-based fsync
//
// - tragic errors handling
//   - what errors cause whole queue to be broken
//   - where to put try/catch for these errors


public class Queue implements Closeable {
    protected long seqNum;
    protected HeadPage headPage;

    // complete list of all non fully acked pages. note that exact sequenciality by pageNum cannot be assumed
    // because any fully acked page will be removed from this list potentially creating pageNum gaps in the list.
    protected final List<TailPage> tailPages;

    // this list serves the only purpose of quickly retrieving the first unread page, operation necessary on every read
    // reads will simply remove the first page from the list when fully read and writes will append new pages upon beheading
    protected final List<TailPage> unreadTailPages;

    protected volatile long unreadCount;

    protected volatile long currentByteSize;

    private final CheckpointIO checkpointIO;
    private final PageIOFactory pageIOFactory;
    private final int pageCapacity;
    private final long maxBytes;
    private final String dirPath;
    private final int maxUnread;
    private final int checkpointMaxAcks;
    private final int checkpointMaxWrites;
    private final int checkpointMaxInterval;

    private final AtomicBoolean closed;

    // deserialization
    private final Class elementClass;
    private final Method deserializeMethod;

    // thread safety
    final Lock lock = new ReentrantLock();
    final Condition notFull  = lock.newCondition();
    final Condition notEmpty = lock.newCondition();

    public Queue(Settings settings) {
        this(
                settings.getDirPath(),
                settings.getCapacity(),
                settings.getQueueMaxBytes(),
                settings.getCheckpointIOFactory().build(settings.getDirPath()),
                settings.getPageIOFactory(),
                settings.getElementClass(),
                settings.getMaxUnread(),
                settings.getCheckpointMaxWrites(),
                settings.getCheckpointMaxAcks(),
                settings.getCheckpointMaxInterval()
        );
    }

    public Queue(String dirPath, int pageCapacity, long maxBytes, CheckpointIO checkpointIO, PageIOFactory pageIOFactory, Class elementClass, int maxUnread, int checkpointMaxWrites, int checkpointMaxAcks, int checkpointMaxInterval) {
        this.dirPath = dirPath;
        this.pageCapacity = pageCapacity;
        this.maxBytes = maxBytes;
        this.checkpointIO = checkpointIO;
        this.pageIOFactory = pageIOFactory;
        this.elementClass = elementClass;
        this.tailPages = new ArrayList<>();
        this.unreadTailPages = new ArrayList<>();
        this.closed = new AtomicBoolean(true); // not yet opened
        this.maxUnread = maxUnread;
        this.checkpointMaxAcks = checkpointMaxAcks;
        this.checkpointMaxWrites = checkpointMaxWrites;
        this.checkpointMaxInterval = checkpointMaxInterval;
        this.unreadCount = 0;
        this.currentByteSize = 0;

        // retrieve the deserialize method
        try {
            Class[] cArg = new Class[1];
            cArg[0] = byte[].class;
            this.deserializeMethod = this.elementClass.getDeclaredMethod("deserialize", cArg);
        } catch (NoSuchMethodException e) {
            throw new QueueRuntimeException("cannot find deserialize method on class " + this.elementClass.getName(), e);
        }
    }

    // moved queue opening logic in open() method until we have something in place to used in-memory checkpoints for testing
    // because for now we need to pass a Queue instance to the Page and we don't want to trigger a Queue recovery when
    // testing Page
    public void open() throws IOException {
        final int headPageNum;

        if (!this.closed.get()) { throw new IOException("queue already opened"); }

        Checkpoint headCheckpoint;
        try {
            headCheckpoint = this.checkpointIO.read(checkpointIO.headFileName());
        } catch (NoSuchFileException e) {
            headCheckpoint = null;
        }

        // if there is no head checkpoint, create a new headpage and checkpoint it and exit method
        if (headCheckpoint == null) {
            this.seqNum = 0;
            headPageNum = 0;

            newCheckpointedHeadpage(headPageNum);
            this.closed.set(false);

            return;
        }

        // at this point we have a head checkpoint to figure queue recovery

        // reconstruct all tail pages state upto but excluding the head page
        for (int pageNum = headCheckpoint.getFirstUnackedPageNum(); pageNum < headCheckpoint.getPageNum(); pageNum++) {

            // all tail checkpoints in the sequence should exist, if not abort mission with a NoSuchFileException
            Checkpoint tailCheckpoint = this.checkpointIO.read(this.checkpointIO.tailFileName(pageNum));

            PageIO pageIO = this.pageIOFactory.build(pageNum, this.pageCapacity, this.dirPath);

            add(tailCheckpoint, pageIO);
        }

        // transform the head page into a tail page only if the headpage is non-empty
        // in both cases it will be checkpointed to track any changes in the firstUnackedPageNum when reconstructing the tail pages

        if (headCheckpoint.getMinSeqNum() <= 0 && headCheckpoint.getElementCount() <= 0) {
            // head page is empty, let's keep it as-is

            PageIO headPageIO = this.pageIOFactory.build(headCheckpoint.getPageNum(), this.pageCapacity, this.dirPath);
            this.headPage = new HeadPage(headCheckpoint, this, headPageIO);
            this.currentByteSize += headPageIO.getCapacity();

            // but checkpoint it to update the firstUnackedPageNum if it changed
            this.headPage.checkpoint();
        } else {
            // head page is non-empty, transform it into a tail page and create a new empty head page

            PageIO pageIO = this.pageIOFactory.build(headCheckpoint.getPageNum(), this.pageCapacity, this.dirPath);

            TailPage p = new TailPage(headCheckpoint, this, pageIO);
            p.checkpoint();
            add(headCheckpoint, pageIO);

            headPageNum = headCheckpoint.getPageNum() + 1;
            newCheckpointedHeadpage(headPageNum);

            // track the seqNum as we add this new tail page, prevent empty tailPage with a minSeqNum of 0 to reset seqNum
            if (headCheckpoint.maxSeqNum() > this.seqNum) { this.seqNum = headCheckpoint.maxSeqNum(); }
         }

        // only activate the first tail page
        if (tailPages.size() > 0) {
            this.tailPages.get(0).getPageIO().activate();
        }

        // TODO: here do directory traversal and cleanup lingering pages? could be a background operations to not delay queue start?

        this.closed.set(false);
    }

    private void add(Checkpoint checkpoint, PageIO pageIO) throws IOException {
        if (checkpoint.isFullyAcked()) {
            // first make sure any fully acked page per the checkpoint is purged if not already
            try { pageIO.purge(); } catch (NoSuchFileException e) { /* ignore */ }

            // we want to keep all the "middle" checkpoints between the first unacked tail page and the head page
            // to always have a contiguous sequence of checkpoints which helps figuring queue integrity. for this
            // we will remove any prepended fully acked tail pages but keep all other checkpoints between the first
            // unacked tail page and the head page. we did however purge the data file to free disk resources.

            if (this.tailPages.size() == 0) {
                // this is the first tail page and it is fully acked so just purge it
                this.checkpointIO.purge(this.checkpointIO.tailFileName(checkpoint.getPageNum()));
            } else {
                // create a tail page with a null PageIO and add it to tail pages but not unreadTailPages
                // since it is fully read because also fully acked
                this.tailPages.add(new TailPage(checkpoint, this, null));
            }
        } else {
            TailPage p = new TailPage(checkpoint, this, pageIO);
            this.tailPages.add(p);
            this.unreadTailPages.add(p);
            this.unreadCount += p.unreadCount();
            this.currentByteSize += pageIO.getCapacity();

            // for now deactivate all tail pages, we will only reactivate the first one at the end
            pageIO.deactivate();
        }

        // track the seqNum as we rebuild tail pages, prevent empty pages with a minSeqNum of 0 to reset seqNum
        if (checkpoint.maxSeqNum() > this.seqNum) {
            this.seqNum = checkpoint.maxSeqNum();
        }

    }

    // create a new empty headpage for the given pageNum and imidiately checkpoint it
    // @param pageNum the page number of the new head page
    private void newCheckpointedHeadpage(int pageNum) throws IOException {
        PageIO headPageIO = this.pageIOFactory.build(pageNum, this.pageCapacity, this.dirPath);
        this.headPage = new HeadPage(pageNum, this, headPageIO);
        this.headPage.forceCheckpoint();
        this.currentByteSize += headPageIO.getCapacity();
    }

    // @param element the Queueable object to write to the queue
    // @return long written sequence number
    public long write(Queueable element) throws IOException {
        long seqNum = nextSeqNum();
        byte[] data = element.serialize();

        if (! this.headPage.hasCapacity(data.length)) {
            throw new IOException("data to be written is bigger than page capacity");
        }

        // the write strategy with regard to the isFull() state is to assume there is space for this element
        // and write it, then after write verify if we just filled the queue and wait on the notFull condition
        // *after* the write which is both safer for a crash condition, and the queue closing sequence. In the former case
        // holding an element in memory while wainting for the notFull condition would mean always having the current write
        // element at risk in the always-full queue state. In the later, when closing a full queue, it would be impossible
        // to write the current element.

        lock.lock();
        try {
            boolean wasEmpty = (firstUnreadPage() == null);

            // create a new head page if the current does not have suffient space left for data to be written
            if (! this.headPage.hasSpace(data.length)) {
                // beheading includes checkpoint+fsync if required
                TailPage tailPage = this.headPage.behead();

                this.tailPages.add(tailPage);
                if (! tailPage.isFullyRead()) {
                    this.unreadTailPages.add(tailPage);
                }

                // create new head page
                newCheckpointedHeadpage(tailPage.pageNum + 1);
            }

            this.headPage.write(data, seqNum, this.checkpointMaxWrites);
            this.unreadCount++;

            // if the queue was empty before write, signal non emptiness
            if (wasEmpty) { notEmpty.signal(); }

            // now check if we reached a queue full state and block here until it is not full
            // for the next write or the queue was closed.
            while (isFull() && !isClosed()) {
                try {
                    notFull.await();
                } catch (InterruptedException e) {
                    // the thread interrupt() has been called while in the await() blocking call.
                    // at this point the interrupted flag is reset and Thread.interrupted() will return false
                    // to any upstream calls on it. for now our choice is to return normally and set back
                    // the Thread.interrupted() flag so it can be checked upstream.

                    // this is a bit tricky in the case of the queue full condition blocking state.
                    // TODO: we will want to avoid initiating a new write operation if Thread.interrupted() was called.

                    // set back the interrupted flag
                    Thread.currentThread().interrupt();

                    return seqNum;
                }
            }

            return seqNum;
        } finally {
            lock.unlock();
        }
    }

    // @return true if the queue is deemed at full capacity
    public boolean isFull() {
        // TODO: I am not sure if having unreadCount as volatile is sufficient here. all unreadCount updates are done inside syncronized
        // TODO: sections, I believe that to only read the value here, having it as volatile is sufficient?
        if ((this.maxBytes > 0) && this.currentByteSize >= this.maxBytes) {
            return true;
        } else {
            return ((this.maxUnread > 0) && this.unreadCount >= this.maxUnread);
        }
    }

    // @param seqNum the element sequence number upper bound for which persistence should be garanteed (by fsync'ing)
    public void ensurePersistedUpto(long seqNum) throws IOException{
        lock.lock();
        try {
            this.headPage.ensurePersistedUpto(seqNum);
        } finally {
            lock.unlock();
        }
    }

    // non-blockin queue read
    // @param limit read the next bach of size up to this limit. the returned batch size can be smaller than than the requested limit if fewer elements are available
    // @return Batch the batch containing 1 or more element up to the required limit or null of no elements were available
    public Batch nonBlockReadBatch(int limit) throws IOException {
        lock.lock();
        try {
            Page p = firstUnreadPage();
            return (p == null) ? null : _readPageBatch(p, limit);
        } finally {
            lock.unlock();
        }
    }

    // blocking readBatch notes:
    //   the queue close() notifies all pending blocking read so that they unblock if the queue is being closed.
    //   this means that all blocking read methods need to verify for the queue close condition.
    //
    // blocking queue read until elements are available for read
    // @param limit read the next bach of size up to this limit. the returned batch size can be smaller than than the requested limit if fewer elements are available
    // @return Batch the batch containing 1 or more element up to the required limit or null if no elements were available or the blocking call was interrupted
    public Batch readBatch(int limit) throws IOException {
        Page p;

        lock.lock();
        try {
            while ((p = firstUnreadPage()) == null && !isClosed()) {
                try {
                    notEmpty.await();
                } catch (InterruptedException e) {
                    // the thread interrupt() has been called while in the await() blocking call.
                    // at this point the interrupted flag is reset and Thread.interrupted() will return false
                    // to any upstream calls on it. for now our choice is to simply return null and set back
                    // the Thread.interrupted() flag so it can be checked upstream.

                    // set back the interrupted flag
                    Thread.currentThread().interrupt();

                    return null;
                }
            }

            // need to check for close since it is a condition for exiting the while loop
            return (isClosed()) ? null : _readPageBatch(p, limit);
        } finally {
            lock.unlock();
        }
    }

    // blocking queue read until elements are available for read or the given timeout is reached.
    // @param limit read the next batch of size up to this limit. the returned batch size can be smaller than than the requested limit if fewer elements are available
    // @param timeout the maximum time to wait in milliseconds
    // @return Batch the batch containing 1 or more element up to the required limit or null if no elements were available or the blocking call was interrupted
    public Batch readBatch(int limit, long timeout) throws IOException {
        Page p;

        lock.lock();
        try {
            // wait only if queue is empty
            if ((p = firstUnreadPage()) == null) {
                try {
                    notEmpty.await(timeout, TimeUnit.MILLISECONDS);
                } catch (InterruptedException e) {
                    // the thread interrupt() has been called while in the await() blocking call.
                    // at this point the interrupted flag is reset and Thread.interrupted() will return false
                    // to any upstream calls on it. for now our choice is to simply return null and set back
                    // the Thread.interrupted() flag so it can be checked upstream.

                    // set back the interrupted flag
                    Thread.currentThread().interrupt();

                    return null;
                }

                // if after returnining from wait queue is still empty, or the queue was closed return null
                if ((p = firstUnreadPage()) == null || isClosed()) { return null; }
            }

            return _readPageBatch(p, limit);
        } finally {
            lock.unlock();
        }
    }

    private Batch _readPageBatch(Page p, int limit) throws IOException {
        boolean wasFull = isFull();

        Batch b = p.readBatch(limit);
        this.unreadCount -= b.size();

        if (p.isFullyRead()) { removeUnreadPage(p); }
        if (wasFull) { notFull.signal(); }

        return b;
    }

    private static class TailPageResult {
        public TailPage page;
        public int index;

        public TailPageResult(TailPage page, int index) {
            this.page = page;
            this.index = index;
        }
    }

    // perform a binary search through tail pages to find in which page this seqNum falls into
    private TailPageResult binaryFindPageForSeqnum(long seqNum) {
        int lo = 0;
        int hi = this.tailPages.size() - 1;
        while (lo <= hi) {
            int mid = lo + (hi - lo) / 2;
            TailPage p = this.tailPages.get(mid);

            if (seqNum < p.getMinSeqNum()) {
                hi = mid - 1;
            } else if (seqNum >= (p.getMinSeqNum() + p.getElementCount())) {
                lo = mid + 1;
            } else {
                return new TailPageResult(p, mid);
            }
        }
        return null;
    }

    // perform a linear search through tail pages to find in which page this seqNum falls into
    private TailPageResult linearFindPageForSeqnum(long seqNum) {
        for (int i = 0; i < this.tailPages.size(); i++) {
            TailPage p = this.tailPages.get(i);
            if (p.getMinSeqNum() > 0 && seqNum >= p.getMinSeqNum() && seqNum < p.getMinSeqNum() + p.getElementCount()) {
                return new TailPageResult(p, i);
            }
        }
        return null;
    }

    // ack a list of seqNums that are assumed to be all part of the same page, leveraging the fact that batches are also created from
    // same-page elements. A fully acked page will trigger a checkpoint for that page. Also if a page has more than checkpointMaxAcks
    // acks since last checkpoint it will also trigger a checkpoint.
    // @param seqNums the list of same-page sequence numbers to ack
    public void ack(List<Long> seqNums) throws IOException {
        // as a first implementation we assume that all batches are created from the same page
        // so we will avoid multi pages acking here for now

        // find the page to ack by travesing from oldest tail page
        long firstAckSeqNum = seqNums.get(0);

        lock.lock();
        try {
            TailPageResult result = null;

            if (this.tailPages.size() > 0) {
                // short-circuit: first check in the first tail page as it is the most likely page where acking will happen
                TailPage p = this.tailPages.get(0);
                if (p.getMinSeqNum() > 0 && firstAckSeqNum >= p.getMinSeqNum() && firstAckSeqNum < p.getMinSeqNum() + p.getElementCount()) {
                    result = new TailPageResult(p, 0);
                } else {
                    // dual search strategy: if few tail pages search linearily otherwise perform binary search
                    result = (this.tailPages.size() > 3) ? binaryFindPageForSeqnum(firstAckSeqNum) : linearFindPageForSeqnum(firstAckSeqNum);
                }
            }

            if (result == null) {
                // if not found then it is in head page
                assert this.headPage.getMinSeqNum() > 0 && firstAckSeqNum >= this.headPage.getMinSeqNum() && firstAckSeqNum < this.headPage.getMinSeqNum() + this.headPage.getElementCount():
                        String.format("seqNum=%d is not in head page with minSeqNum=%d", firstAckSeqNum, this.headPage.getMinSeqNum());

                // page acking checkpoints fully acked pages
                this.headPage.ack(seqNums, this.checkpointMaxAcks);
            } else {
                // page acking also checkpoints fully acked pages or upon reaching the checkpointMaxAcks threshold
                result.page.ack(seqNums, this.checkpointMaxAcks);

                // cleanup fully acked tail page
                if (result.page.isFullyAcked()) {
                    this.tailPages.remove(result.index);

                    // remove page data file regardless if it is the first or a middle tail page to free resources
                    result.page.purge();
                    this.currentByteSize -= result.page.getPageIO().getCapacity();

                     if (result.index == 0) {
                        // if this is the first page also remove checkpoint file
                        this.checkpointIO.purge(this.checkpointIO.tailFileName(result.page.getPageNum()));

                         // and see if next "first tail page" is also fully acked and remove checkpoint file
                        while (this.tailPages.size() > 0) {
                            TailPage p = this.tailPages.get(0);
                            if (!p.isFullyAcked()) { break; }
                            this.checkpointIO.purge(this.checkpointIO.tailFileName(p.getPageNum()));
                            this.tailPages.remove(0);
                        }
                    }
                }

                this.headPage.checkpoint();
            }
        } finally {
            lock.unlock();
        }
    }

    public CheckpointIO getCheckpointIO() {
        return this.checkpointIO;
    }

    // deserialize a byte array into the required element class.
    // @param bytes the byte array to deserialize
    // @return Queueable the deserialized byte array into the required Queuable interface implementation concrete class
    public Queueable deserialize(byte[] bytes) {
        try {
            return (Queueable)this.deserializeMethod.invoke(this.elementClass, bytes);
        } catch (IllegalAccessException|InvocationTargetException e) {
            throw new QueueRuntimeException("deserialize invocation error", e);
        }
    }

    public void close() throws IOException {
        // TODO: review close strategy and exception handling and resiliency of first closing tail pages if crash in the middle

        if (closed.getAndSet(true) == false) {
            lock.lock();
            try {
                // TODO: not sure if we need to do this here since the headpage close will also call ensurePersited
                ensurePersistedUpto(this.seqNum);

                for (TailPage p : this.tailPages) { p.close(); }
                this.headPage.close();

                // release all referenced objects
                this.tailPages.clear();
                this.unreadTailPages.clear();
                this.headPage = null;

                // unblock blocked reads which will return null by checking of isClosed()
                // no data will be lost because the actual read has not been performed
                notEmpty.signalAll();


                // unblock blocked writes. a write is blocked *after* the write has been performed so
                // unblocking is safe and will return from the write call
                notFull.signalAll();
            } finally {
                lock.unlock();
            }
        }
    }

    protected Page firstUnreadPage() throws IOException {
        // look at head page if no unreadTailPages
        return (this.unreadTailPages.isEmpty()) ? (this.headPage.isFullyRead() ? null : this.headPage) : this.unreadTailPages.get(0);
    }

    private void removeUnreadPage(Page p) {
        // HeadPage is not part of the unreadTailPages, just ignore
        if (p instanceof TailPage){
            // the page to remove should always be the first one
            assert this.unreadTailPages.get(0) == p : String.format("unread page is not first in unreadTailPages list");
            this.unreadTailPages.remove(0);
        }
    }

    protected int firstUnackedPageNum() {
        if (this.tailPages.isEmpty()) {
            return this.headPage.getPageNum();
        }
        return this.tailPages.get(0).getPageNum();
    }

    protected long nextSeqNum() {
        return this.seqNum += 1;
    }

    protected boolean isClosed() {
        return this.closed.get();
    }
}
