package org.logstash.ackedqueue;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.FileLockFactory;
import org.logstash.LockException;
import org.logstash.ackedqueue.io.CheckpointIO;
import org.logstash.ackedqueue.io.LongVector;
import org.logstash.ackedqueue.io.PageIO;
import org.logstash.ackedqueue.io.PageIOFactory;

import java.io.Closeable;
import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.nio.channels.FileLock;
import java.nio.file.NoSuchFileException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
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

public final class Queue implements Closeable {

    private long seqNum;

    protected Page headPage;

    // complete list of all non fully acked pages. note that exact sequentially by pageNum cannot be assumed
    // because any fully acked page will be removed from this list potentially creating pageNum gaps in the list.
    protected final List<Page> tailPages;

    // this list serves the only purpose of quickly retrieving the first unread page, operation necessary on every read
    // reads will simply remove the first page from the list when fully read and writes will append new pages upon beheading
    protected final List<Page> unreadTailPages;

    // checkpoints that were not purged in the acking code to keep contiguous checkpoint files
    // regardless of the correcponding data file purge.
    private final Set<Integer> preservedCheckpoints;

    protected volatile long unreadCount;
    private volatile long currentByteSize;

    private final CheckpointIO checkpointIO;
    private final PageIOFactory pageIOFactory;
    private final int pageCapacity;
    private final long maxBytes;
    private final String dirPath;
    private final int maxUnread;
    private final int checkpointMaxAcks;
    private final int checkpointMaxWrites;

    private final AtomicBoolean closed;

    // deserialization
    private final Class<? extends Queueable> elementClass;
    private final Method deserializeMethod;

    // thread safety
    private final Lock lock = new ReentrantLock();
    private final Condition notFull  = lock.newCondition();
    private final Condition notEmpty = lock.newCondition();

    // exclusive dir access
    private FileLock dirLock;
    private final static String LOCK_NAME = ".lock";

    private static final Logger logger = LogManager.getLogger(Queue.class);

    public Queue(Settings settings) {
        this.dirPath = settings.getDirPath();
        this.pageCapacity = settings.getCapacity();
        this.maxBytes = settings.getQueueMaxBytes();
        this.checkpointIO = settings.getCheckpointIOFactory().build(dirPath);
        this.pageIOFactory = settings.getPageIOFactory();
        this.elementClass = settings.getElementClass();
        this.tailPages = new ArrayList<>();
        this.unreadTailPages = new ArrayList<>();
        this.preservedCheckpoints = new HashSet<>();
        this.closed = new AtomicBoolean(true); // not yet opened
        this.maxUnread = settings.getMaxUnread();
        this.checkpointMaxAcks = settings.getCheckpointMaxAcks();
        this.checkpointMaxWrites = settings.getCheckpointMaxWrites();
        this.unreadCount = 0L;
        this.currentByteSize = 0L;

        // retrieve the deserialize method
        try {
            final Class<?>[] cArg = new Class<?>[1];
            cArg[0] = byte[].class;
            this.deserializeMethod = this.elementClass.getDeclaredMethod("deserialize", cArg);
        } catch (NoSuchMethodException e) {
            throw new QueueRuntimeException("cannot find deserialize method on class " + this.elementClass.getName(), e);
        }
    }

    public String getDirPath() {
        return this.dirPath;
    }

    public long getMaxBytes() {
        return this.maxBytes;
    }

    public long getMaxUnread() {
        return this.maxUnread;
    }

    public long getCurrentByteSize() {
        return this.currentByteSize;
    }

    public long getPersistedByteSize() {
        lock.lock();
        try {
            final long size;
            if (headPage == null) {
                size = 0L;
            } else {
                size = headPage.getPageIO().getHead()
                    + tailPages.stream().mapToLong(p -> p.getPageIO().getHead()).sum();
            }
            return size;
        } finally {
            lock.unlock();
        }
    }

    public int getPageCapacity() {
        return this.pageCapacity;
    }

    public long getUnreadCount() {
        return this.unreadCount;
    }

    // moved queue opening logic in open() method until we have something in place to used in-memory checkpoints for testing
    // because for now we need to pass a Queue instance to the Page and we don't want to trigger a Queue recovery when
    // testing Page
    public void open() throws IOException {
        final int headPageNum;

        if (!this.closed.get()) { throw new IOException("queue already opened"); }

        lock.lock();
        try {
            // verify exclusive access to the dirPath
            this.dirLock = FileLockFactory.obtainLock(this.dirPath, LOCK_NAME);

            Checkpoint headCheckpoint;
            try {
                headCheckpoint = this.checkpointIO.read(checkpointIO.headFileName());
            } catch (NoSuchFileException e) {
                // if there is no head checkpoint, create a new headpage and checkpoint it and exit method

                logger.debug("No head checkpoint found at: {}, creating new head page", checkpointIO.headFileName());

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
                Checkpoint cp = this.checkpointIO.read(this.checkpointIO.tailFileName(pageNum));

                logger.debug("opening tail page: {}, in: {}, with checkpoint: {}", pageNum, this.dirPath, cp.toString());

                PageIO pageIO = this.pageIOFactory.build(pageNum, this.pageCapacity, this.dirPath);
                addIO(cp, pageIO);
            }

            // transform the head page into a tail page only if the headpage is non-empty
            // in both cases it will be checkpointed to track any changes in the firstUnackedPageNum when reconstructing the tail pages

            logger.debug("opening head page: {}, in: {}, with checkpoint: {}", headCheckpoint.getPageNum(), this.dirPath, headCheckpoint.toString());

            PageIO pageIO = this.pageIOFactory.build(headCheckpoint.getPageNum(), this.pageCapacity, this.dirPath);
            pageIO.recover(); // optimistically recovers the head page data file and set minSeqNum and elementCount to the actual read/recovered data

            if (pageIO.getMinSeqNum() != headCheckpoint.getMinSeqNum() || pageIO.getElementCount() != headCheckpoint.getElementCount()) {
                // the recovered page IO shows different minSeqNum or elementCount than the checkpoint, use the page IO attributes

                logger.warn("recovered head data page {} is different than checkpoint, using recovered page information", headCheckpoint.getPageNum());
                logger.debug("head checkpoint minSeqNum={} or elementCount={} is different than head pageIO minSeqNum={} or elementCount={}", headCheckpoint.getMinSeqNum(), headCheckpoint.getElementCount(), pageIO.getMinSeqNum(), pageIO.getElementCount());

                long firstUnackedSeqNum = headCheckpoint.getFirstUnackedSeqNum();
                if (firstUnackedSeqNum < pageIO.getMinSeqNum()) {
                    logger.debug("head checkpoint firstUnackedSeqNum={} is < head pageIO minSeqNum={}, using pageIO minSeqNum", firstUnackedSeqNum, pageIO.getMinSeqNum());
                    firstUnackedSeqNum = pageIO.getMinSeqNum();
                }
                headCheckpoint = new Checkpoint(headCheckpoint.getPageNum(), headCheckpoint.getFirstUnackedPageNum(), firstUnackedSeqNum, pageIO.getMinSeqNum(), pageIO.getElementCount());
            }
            this.headPage = PageFactory.newHeadPage(headCheckpoint, this, pageIO);

            if (this.headPage.getMinSeqNum() <= 0 && this.headPage.getElementCount() <= 0) {
                // head page is empty, let's keep it as-is

                this.currentByteSize += pageIO.getCapacity();

                // but checkpoint it to update the firstUnackedPageNum if it changed
                this.headPage.checkpoint();
            } else {
                // head page is non-empty, transform it into a tail page and create a new empty head page
                this.headPage.behead();
                addPage(headCheckpoint, this.headPage);

                headPageNum = headCheckpoint.getPageNum() + 1;
                newCheckpointedHeadpage(headPageNum);

                // track the seqNum as we add this new tail page, prevent empty tailPage with a minSeqNum of 0 to reset seqNum
                if (headCheckpoint.maxSeqNum() > this.seqNum) {
                    this.seqNum = headCheckpoint.maxSeqNum();
                }
            }

            // only activate the first tail page
            if (tailPages.size() > 0) {
                this.tailPages.get(0).getPageIO().activate();
            }

            // TODO: here do directory traversal and cleanup lingering pages? could be a background operations to not delay queue start?

            this.closed.set(false);
        } catch (LockException e) {
            throw new LockException("The queue failed to obtain exclusive access, cause: " + e.getMessage());
        } finally {
            lock.unlock();
        }
    }

    // TODO: addIO and addPage are almost identical - we should refactor to DRY it up.

    // addIO is basically the same as addPage except that it avoid calling PageIO.open
    // before actually purging the page if it is fully acked. This avoid dealing with
    // zero byte page files that are fully acked.
    // see issue #7809
    private void addIO(Checkpoint checkpoint, PageIO pageIO) throws IOException {
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
                // TODO: I don't like this null pageIO tail page...
                this.tailPages.add(PageFactory.newTailPage(checkpoint, this, null));
            }
        } else {
            pageIO.open(checkpoint.getMinSeqNum(), checkpoint.getElementCount());
            Page page = PageFactory.newTailPage(checkpoint, this, pageIO);

            this.tailPages.add(page);
            this.unreadTailPages.add(page);
            this.unreadCount += page.unreadCount();
            this.currentByteSize += page.getPageIO().getCapacity();

            // for now deactivate all tail pages, we will only reactivate the first one at the end
            page.getPageIO().deactivate();
        }

        // track the seqNum as we rebuild tail pages, prevent empty pages with a minSeqNum of 0 to reset seqNum
        if (checkpoint.maxSeqNum() > this.seqNum) {
            this.seqNum = checkpoint.maxSeqNum();
        }
    }

    // add a read tail page into this queue structures but also verify that this tail page
    // is not fully acked in which case it will be purged
    private void addPage(Checkpoint checkpoint, Page page) throws IOException {
        if (checkpoint.isFullyAcked()) {
            // first make sure any fully acked page per the checkpoint is purged if not already
            try { page.getPageIO().purge(); } catch (NoSuchFileException e) { /* ignore */ }

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
                // TODO: I don't like this null pageIO tail page...
                this.tailPages.add(PageFactory.newTailPage(checkpoint, this, null));
            }
        } else {
            this.tailPages.add(page);
            this.unreadTailPages.add(page);
            this.unreadCount += page.unreadCount();
            this.currentByteSize += page.getPageIO().getCapacity();

            // for now deactivate all tail pages, we will only reactivate the first one at the end
            page.getPageIO().deactivate();
        }

        // track the seqNum as we rebuild tail pages, prevent empty pages with a minSeqNum of 0 to reset seqNum
        if (checkpoint.maxSeqNum() > this.seqNum) {
            this.seqNum = checkpoint.maxSeqNum();
        }
    }

    // create a new empty headpage for the given pageNum and immediately checkpoint it
    // @param pageNum the page number of the new head page
    private void newCheckpointedHeadpage(int pageNum) throws IOException {
        PageIO headPageIO = this.pageIOFactory.build(pageNum, this.pageCapacity, this.dirPath);
        headPageIO.create();
        this.headPage = PageFactory.newHeadPage(pageNum, this, headPageIO);
        this.headPage.forceCheckpoint();
        this.currentByteSize += headPageIO.getCapacity();
    }

    // @param element the Queueable object to write to the queue
    // @return long written sequence number
    public long write(Queueable element) throws IOException {
        byte[] data = element.serialize();

        // the write strategy with regard to the isFull() state is to assume there is space for this element
        // and write it, then after write verify if we just filled the queue and wait on the notFull condition
        // *after* the write which is both safer for a crash condition, and the queue closing sequence. In the former case
        // holding an element in memory while waiting for the notFull condition would mean always having the current write
        // element at risk in the always-full queue state. In the later, when closing a full queue, it would be impossible
        // to write the current element.

        lock.lock();
        try {
            if (! this.headPage.hasCapacity(data.length)) {
                throw new IOException("data to be written is bigger than page capacity");
            }

            // create a new head page if the current does not have sufficient space left for data to be written
            if (! this.headPage.hasSpace(data.length)) {

                // TODO: verify queue state integrity WRT Queue.open()/recover() at each step of this process

                int newHeadPageNum = this.headPage.pageNum + 1;

                if (this.headPage.isFullyAcked()) {
                    // purge the old headPage because its full and fully acked
                    // there is no checkpoint file to purge since just creating a new TailPage from a HeadPage does
                    // not trigger a checkpoint creation in itself
                    this.headPage.purge();
                    currentByteSize -= this.headPage.getPageIO().getCapacity();
                } else {
                    // beheading includes checkpoint+fsync if required
                    this.headPage.behead();
                    this.tailPages.add(this.headPage);
                    if (! this.headPage.isFullyRead()) {
                        this.unreadTailPages.add(this.headPage);
                    }
                }

                // create new head page
                newCheckpointedHeadpage(newHeadPageNum);
            }

            long seqNum = this.seqNum += 1;
            this.headPage.write(data, seqNum, this.checkpointMaxWrites);
            this.unreadCount++;
            
            notEmpty.signal();

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

    /**
     * <p>Checks if the Queue is full, with "full" defined as either of:</p>
     * <p>Assuming a maximum size of the queue larger than 0 is defined:</p>
     * <ul>
     *     <li>The sum of the size of all allocated pages is more than the allowed maximum Queue 
     *     size</li>
     *     <li>The sum of the size of all allocated pages equal to the allowed maximum Queue size 
     *     and the current head page has no remaining capacity.</li>
     * </ul>
     * <p>or assuming a max unread count larger than 0, is defined "full" is also defined as:</p>
     * <ul>
     *     <li>The current number of unread events exceeds or is equal to the configured maximum 
     *     number of allowed unread events.</li>
     * </ul>
     * @return True iff the queue is full
     */
    public boolean isFull() {
        lock.lock();
        try {
            if (this.maxBytes > 0L && (
                this.currentByteSize > this.maxBytes
                    || this.currentByteSize == this.maxBytes && !this.headPage.hasSpace(1)
            )) {
                return true;
            } else {
                return ((this.maxUnread > 0) && this.unreadCount >= this.maxUnread);
            }
        } finally {
            lock.unlock();
        }
    }

    /**
     * Queue is considered empty if it does not contain any tail page and the headpage has no element or all
     * elements are acked
     *
     * TODO: note that this should be the same as isFullyAcked once fixed per https://github.com/elastic/logstash/issues/7570
     *
     * @return true if the queue has no tail page and the head page is empty.
     */
    public boolean isEmpty() {
        lock.lock();
        try {
            return this.tailPages.isEmpty() && this.headPage.isEmpty();
        } finally {
            lock.unlock();
        }

    }

    // @return true if the queue is fully acked, which implies that it is fully read which works as an "empty" state.
    public boolean isFullyAcked() {
        lock.lock();
        try {
            return this.tailPages.isEmpty() ? this.headPage.isFullyAcked() : false;
        } finally {
            lock.unlock();
        }
    }

    // @param seqNum the element sequence number upper bound for which persistence should be guaranteed (by fsync'ing)
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

                // if after returning from wait queue is still empty, or the queue was closed return null
                if ((p = firstUnreadPage()) == null || isClosed()) { return null; }
            }

            return _readPageBatch(p, limit);
        } finally {
            lock.unlock();
        }
    }

    private Batch _readPageBatch(Page p, int limit) throws IOException {
        boolean wasFull = isFull();

        SequencedList<byte[]> serialized = p.read(limit);

        this.unreadCount -= serialized.getElements().size();

        if (p.isFullyRead()) { removeUnreadPage(p); }
        if (wasFull) { notFull.signalAll(); }

        return new Batch(serialized, this);
    }

    private static class TailPageResult {
        public Page page;
        public int index;

        public TailPageResult(Page page, int index) {
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
            Page p = this.tailPages.get(mid);

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
            Page p = this.tailPages.get(i);
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
    public void ack(LongVector seqNums) throws IOException {
        // as a first implementation we assume that all batches are created from the same page
        // so we will avoid multi pages acking here for now

        // find the page to ack by traversing from oldest tail page
        long firstAckSeqNum = seqNums.get(0);

        lock.lock();
        try {
            TailPageResult result = null;

            if (this.tailPages.size() > 0) {
                // short-circuit: first check in the first tail page as it is the most likely page where acking will happen
                Page p = this.tailPages.get(0);
                if (p.getMinSeqNum() > 0 && firstAckSeqNum >= p.getMinSeqNum() && firstAckSeqNum < p.getMinSeqNum() + p.getElementCount()) {
                    result = new TailPageResult(p, 0);
                } else {
                    // dual search strategy: if few tail pages search linearly otherwise perform binary search
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
                    boolean wasFull = isFull();

                    this.tailPages.remove(result.index);

                    // remove page data file regardless if it is the first or a middle tail page to free resources
                    result.page.purge();
                    this.currentByteSize -= result.page.getPageIO().getCapacity();

                    if (result.index != 0) {
                        // this an in-between page, we don't purge it's checkpoint to preserve checkpoints sequence on disk
                        // save that checkpoint so that if it becomes the first checkpoint it can be purged later on.
                        this.preservedCheckpoints.add(result.page.getPageNum());
                    } else {
                        // if this is the first page also remove checkpoint file
                        this.checkpointIO.purge(this.checkpointIO.tailFileName(result.page.getPageNum()));

                        // check if there are preserved checkpoints file next to this one and delete them
                        int nextPageNum = result.page.getPageNum() + 1;
                        while (preservedCheckpoints.remove(nextPageNum)) {
                            this.checkpointIO.purge(this.checkpointIO.tailFileName(nextPageNum));
                            nextPageNum++;
                        }
                    }

                    if (wasFull) { notFull.signalAll(); }
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
    // @return Queueable the deserialized byte array into the required Queueable interface implementation concrete class
    public Queueable deserialize(byte[] bytes) {
        try {
            return (Queueable)this.deserializeMethod.invoke(this.elementClass, bytes);
        } catch (IllegalAccessException|InvocationTargetException e) {
            throw new QueueRuntimeException("deserialize invocation error", e);
        }
    }

    @Override
    public void close() throws IOException {
        // TODO: review close strategy and exception handling and resiliency of first closing tail pages if crash in the middle

        if (closed.getAndSet(true) == false) {
            lock.lock();
            try {
                // TODO: not sure if we need to do this here since the headpage close will also call ensurePersisted
                ensurePersistedUpto(this.seqNum);

                for (Page p : this.tailPages) { p.close(); }
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
                try {
                    FileLockFactory.releaseLock(this.dirLock);
                } catch (IOException e) {
                    // log error and ignore
                    logger.error("Queue close releaseLock failed, error={}", e.getMessage());
                } finally {
                    lock.unlock();
                }
            }
        }
    }

    public Page firstUnreadPage() {
        lock.lock();
        try {
            // look at head page if no unreadTailPages
            return (this.unreadTailPages.isEmpty()) ? (this.headPage.isFullyRead() ? null : this.headPage) : this.unreadTailPages.get(0);
        } finally {
            lock.unlock();
        }
    }

    private void removeUnreadPage(Page p) {
        // HeadPage is not part of the unreadTailPages, just ignore
        if (p != this.headPage) {
            // the page to remove should always be the first one
            assert this.unreadTailPages.get(0) == p : String.format("unread page is not first in unreadTailPages list");
            this.unreadTailPages.remove(0);
        }
    }

    public int firstUnackedPageNum() {
        lock.lock();
        try {
            if (this.tailPages.isEmpty()) {
                return this.headPage.getPageNum();
            }
            return this.tailPages.get(0).getPageNum();
        } finally {
            lock.unlock();
        }
    }

    public long getAckedCount() {
        lock.lock();
        try {
            return headPage.ackedSeqNums.cardinality() + tailPages.stream()
                .mapToLong(page -> page.ackedSeqNums.cardinality()).sum();
        } finally {
            lock.unlock();
        }
    }

    public long getUnackedCount() {
        lock.lock();
        try {
            long headPageCount = (headPage.getElementCount() - headPage.ackedSeqNums.cardinality());
            long tailPagesCount = tailPages.stream()
                .mapToLong(page -> (page.getElementCount() - page.ackedSeqNums.cardinality()))
                .sum();
            return headPageCount + tailPagesCount;
        } finally {
            lock.unlock();
        }
    }

    private boolean isClosed() {
        return this.closed.get();
    }
}
