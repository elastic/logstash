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
    protected final List<BeheadedPage> beheadedPages;

    // this list serves the only purpose of quickly retrieving the first unread page, operation necessary on every read
    // reads will simply remove the first page from the list when fully read and writes will append new pages upon beheading
    protected final List<BeheadedPage> unreadBeheadedPages;

    protected volatile long unreadCount;

    private final CheckpointIO checkpointIO;
    private final PageIOFactory pageIOFactory;
    private final int pageCapacity;
    private final String dirPath;
    private final int maxUnread;

    private final AtomicBoolean closed;

    // deserialization
    private final Class elementClass;
    private final Method deserializeMethod;

    // thread safety
    final Lock lock = new ReentrantLock();
    final Condition notFull  = lock.newCondition();
    final Condition notEmpty = lock.newCondition();

    public Queue(Settings settings) {
        this(settings.getDirPath(), settings.getCapacity(), settings.getCheckpointIOFactory().build(settings.getDirPath()), settings.getPageIOFactory(), settings.getElementClass(), settings.getMaxUnread());
    }

    public Queue(String dirPath, int pageCapacity, CheckpointIO checkpointIO, PageIOFactory pageIOFactory, Class elementClass, int maxUnread) {
        this.dirPath = dirPath;
        this.pageCapacity = pageCapacity;
        this.checkpointIO = checkpointIO;
        this.pageIOFactory = pageIOFactory;
        this.elementClass = elementClass;
        this.beheadedPages = new ArrayList<>();
        this.unreadBeheadedPages = new ArrayList<>();
        this.closed = new AtomicBoolean(true); // not yet opened
        this.maxUnread = maxUnread;
        this.unreadCount = 0;

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

        if (!this.closed.get()) {
            throw new IOException("queue already opened");
        }

        Checkpoint headCheckpoint;
        try {
            headCheckpoint = checkpointIO.read(checkpointIO.headFileName());
        } catch (NoSuchFileException e) {
            headCheckpoint = null;
        }

        if (headCheckpoint == null) {
            this.seqNum = 0;
            headPageNum = 0;
        } else {

            // reconstruct all tail pages state upto but excluding the head page
            for (int pageNum = headCheckpoint.getFirstUnackedPageNum(); pageNum < headCheckpoint.getPageNum(); pageNum++) {
                Checkpoint tailCheckpoint = checkpointIO.read(checkpointIO.tailFileName(pageNum));

                if (tailCheckpoint == null) {
                    throw new IOException(checkpointIO.tailFileName(pageNum) + " not found");
                }

                PageIO pageIO = this.pageIOFactory.build(pageNum, this.pageCapacity, this.dirPath);
                BeheadedPage beheadedPage = new BeheadedPage(tailCheckpoint, this, pageIO);

                // if this page is not the first tail page, deactivate it
                // we keep the first tail page activated since we know the next read operation will be in that one
                if (pageNum > headCheckpoint.getFirstUnackedPageNum()) {
                    pageIO.deactivate();
                }

                // track the seqNum as we rebuild tail pages
                if (beheadedPage.maxSeqNum() > this.seqNum) {
                    // prevent empty pages with a minSeqNum of 0 to reset seqNum
                    this.seqNum = beheadedPage.maxSeqNum();
                }

                // the systematic beheading on open below can create empty/fully acked tail pages
                // TODO: add test harness for this and see if/how we should purge empty/fully acked pages
                if (!beheadedPage.isFullyAcked()) {
                    this.beheadedPages.add(beheadedPage);
                    if (! beheadedPage.isFullyRead()) {
                        this.unreadBeheadedPages.add(beheadedPage);
                        this.unreadCount += beheadedPage.unreadCount();
                    }
                }
            }

            // transform the head page into a beheaded tail page
            PageIO pageIO = this.pageIOFactory.build(headCheckpoint.getPageNum(), this.pageCapacity, this.dirPath);
            BeheadedPage beheadedHeadPage = new BeheadedPage(headCheckpoint, this, pageIO);

            // track the seqNum as we rebuild tail pages
            if (beheadedHeadPage.maxSeqNum() > this.seqNum) {
                // prevent empty beheadedHeadPage with a minSeqNum of 0 to reset seqNum
                this.seqNum = beheadedHeadPage.maxSeqNum();
            }

            // the systematic beheading on open above can create empty/fully acked tail pages
            // TODO: add test harness for this and see if/how we should purge empty/fully acked pages
            if (beheadedHeadPage.isFullyAcked()) {
                this.beheadedPages.add(beheadedHeadPage);
                if (! beheadedHeadPage.isFullyRead()) {
                    this.unreadBeheadedPages.add(beheadedHeadPage);
                    this.unreadCount += beheadedHeadPage.unreadCount();
                }

                beheadedHeadPage.checkpoint();
            }

            headPageNum = headCheckpoint.getPageNum() + 1;
        }

        // create new head page
        PageIO pageIO = this.pageIOFactory.build(headPageNum, this.pageCapacity, this.dirPath);
        this.headPage = new HeadPage(headPageNum, this, pageIO);
        this.headPage.checkpoint();

        // TODO: here do directory traversal and cleanup lingering pages? could be a background operations to not delay queue start?

        this.closed.set(false);
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
                BeheadedPage beheadedPage = this.headPage.behead();

                this.beheadedPages.add(beheadedPage);
                if (! beheadedPage.isFullyRead()) {
                    this.unreadBeheadedPages.add(beheadedPage);
                }

                // create new head page
                int headPageNum = beheadedPage.pageNum + 1;
                PageIO pageIO = this.pageIOFactory.build(headPageNum, this.pageCapacity, this.dirPath);
                this.headPage = new HeadPage(headPageNum, this, pageIO);
                this.headPage.checkpoint();
            }

            this.headPage.write(data, seqNum);
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
        return (this.maxUnread > 0) ? this.unreadCount >= this.maxUnread : false;
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
            if (p == null) {
                return null;
            }

            return _readPageBatch(p, limit);
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
            if (isClosed()) { return null; }

            return _readPageBatch(p, limit);
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

        if (p.isFullyRead()) {
            removeUnreadPage(p);
        }

        if (wasFull) { notFull.signal(); }

        return b;
    }

    private static class BeheadedPageResult {
        public BeheadedPage page;
        public int index;

        public BeheadedPageResult(BeheadedPage page, int index) {
            this.page = page;
            this.index = index;
        }
    }

    // perform a binary search through tail pages to find in which page this seqNum falls into
    private BeheadedPageResult binaryFindPageForSeqnum(long seqNum) {
        int lo = 0;
        int hi = this.beheadedPages.size() - 1;
        while (lo <= hi) {
            int mid = lo + (hi - lo) / 2;
            BeheadedPage p = this.beheadedPages.get(mid);

            if (seqNum < p.getMinSeqNum()) {
                hi = mid - 1;
            } else if (seqNum >= (p.getMinSeqNum() + p.getElementCount())) {
                lo = mid + 1;
            } else {
                return new BeheadedPageResult(p, mid);
            }
        }
        return null;
    }

    // perform a linear search through tail pages to find in which page this seqNum falls into
    private BeheadedPageResult linearFindPageForSeqnum(long seqNum) {
        for (int i = 0; i < this.beheadedPages.size(); i++) {
            BeheadedPage p = this.beheadedPages.get(i);
            if (p.getMinSeqNum() > 0 && seqNum >= p.getMinSeqNum() && seqNum < p.getMinSeqNum() + p.getElementCount()) {
                return new BeheadedPageResult(p, i);
            }
        }
        return null;
    }

    public void ack(List<Long> seqNums) throws IOException {
        // as a first implementation we assume that all batches are created from the same page
        // so we will avoid multi pages acking here for now

        // find the page to ack by travesing from oldest tail page
        long firstAckSeqNum = seqNums.get(0);

        lock.lock();
        try {
            // dual search strategy: if few tail pages search linearily otherwise perform binary search
            BeheadedPageResult result = (this.beheadedPages.size() > 3) ? binaryFindPageForSeqnum(firstAckSeqNum) : linearFindPageForSeqnum(firstAckSeqNum);

            if (result == null) {
                // if not found then it is in head page
                assert this.headPage.getMinSeqNum() > 0 && firstAckSeqNum >= this.headPage.getMinSeqNum() && firstAckSeqNum < this.headPage.getMinSeqNum() + this.headPage.getElementCount():
                        String.format("seqNum=%d is not in head page with minSeqNum=%d", firstAckSeqNum, this.headPage.getMinSeqNum());
                this.headPage.ack(seqNums);
            } else {
                result.page.ack(seqNums);

                // cleanup fully acked tail page
                if (result.page.isFullyAcked()) {
                    this.beheadedPages.remove(result.index);
                    this.headPage.checkpoint();
                    result.page.purge();
                }
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

                for (BeheadedPage p : this.beheadedPages) { p.close(); }
                this.headPage.close();

                // release all referenced objects
                this.beheadedPages.clear();
                this.unreadBeheadedPages.clear();
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
        // look at head page if no unreadBeheadedPages
        return (this.unreadBeheadedPages.isEmpty()) ? (this.headPage.isFullyRead() ? null : this.headPage) : this.unreadBeheadedPages.get(0);
    }

    private void removeUnreadPage(Page p) {
        // HeadPage is not part of the unreadBeheadedPages, just ignore
        if (p instanceof BeheadedPage){
            // the page to remove should always be the first one
            assert this.unreadBeheadedPages.get(0) == p : String.format("unread page is not first in unreadBeheadedPages list");
            this.unreadBeheadedPages.remove(0);
        }
    }

    protected int firstUnackedPageNum() {
        if (this.beheadedPages.isEmpty()) {
            return this.headPage.getPageNum();
        }
        return this.beheadedPages.get(0).getPageNum();
    }

    protected long nextSeqNum() {
        return this.seqNum += 1;
    }

    protected boolean isClosed() {
        return this.closed.get();
    }
}
