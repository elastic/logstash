package org.logstash.ackedqueue;

import java.io.Closeable;
import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.nio.channels.FileLock;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.FileLockFactory;
import org.logstash.LockException;
import org.logstash.ackedqueue.io.CheckpointIO;
import org.logstash.ackedqueue.io.FileCheckpointIO;
import org.logstash.ackedqueue.io.MmapPageIOV2;
import org.logstash.ackedqueue.io.PageIO;
import org.logstash.common.FsUtil;

public final class Queue implements Closeable {

    private long seqNum;

    protected Page headPage;

    // complete list of all non fully acked pages. note that exact sequentially by pageNum cannot be assumed
    // because any fully acked page will be removed from this list potentially creating pageNum gaps in the list.
    protected final List<Page> tailPages;

    // this list serves the only purpose of quickly retrieving the first unread page, operation necessary on every read
    // reads will simply remove the first page from the list when fully read and writes will append new pages upon beheading
    protected final List<Page> unreadTailPages;

    protected volatile long unreadCount;

    private final CheckpointIO checkpointIO;
    private final int pageCapacity;
    private final long maxBytes;
    private final Path dirPath;
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
        try {
            final Path queueDir = Paths.get(settings.getDirPath());
            Files.createDirectories(queueDir);
            this.dirPath = queueDir.toRealPath();
        } catch (final IOException ex) {
            throw new IllegalStateException(ex);
        }
        this.pageCapacity = settings.getCapacity();
        this.maxBytes = settings.getQueueMaxBytes();
        this.checkpointIO = new FileCheckpointIO(dirPath);
        this.elementClass = settings.getElementClass();
        this.tailPages = new ArrayList<>();
        this.unreadTailPages = new ArrayList<>();
        this.closed = new AtomicBoolean(true); // not yet opened
        this.maxUnread = settings.getMaxUnread();
        this.checkpointMaxAcks = settings.getCheckpointMaxAcks();
        this.checkpointMaxWrites = settings.getCheckpointMaxWrites();
        this.unreadCount = 0L;

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
        return this.dirPath.toString();
    }

    public long getMaxBytes() {
        return this.maxBytes;
    }

    public long getMaxUnread() {
        return this.maxUnread;
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

    /**
     * Open an existing {@link Queue} or create a new one in the configured path.
     * @throws IOException
     */
    public void open() throws IOException {
        final int headPageNum;

        if (!this.closed.get()) { throw new IOException("queue already opened"); }

        lock.lock();
        try {
            // verify exclusive access to the dirPath
            this.dirLock = FileLockFactory.obtainLock(this.dirPath, LOCK_NAME);

            // Upgrade to serialization format V2
            QueueUpgrade.upgradeQueueDirectoryToV2(dirPath);

            Checkpoint headCheckpoint;
            try {
                headCheckpoint = this.checkpointIO.read(checkpointIO.headFileName());
            } catch (NoSuchFileException e) {
                // if there is no head checkpoint, create a new headpage and checkpoint it and exit method

                logger.debug("No head checkpoint found at: {}, creating new head page", checkpointIO.headFileName());

                this.ensureDiskAvailable(this.maxBytes);

                this.seqNum = 0;
                headPageNum = 0;

                newCheckpointedHeadpage(headPageNum);
                this.closed.set(false);

                return;
            }

            // at this point we have a head checkpoint to figure queue recovery

            // as we load pages, compute actuall disk needed substracting existing pages size to the required maxBytes
            long diskNeeded = this.maxBytes;

            // reconstruct all tail pages state upto but excluding the head page
            for (int pageNum = headCheckpoint.getFirstUnackedPageNum(); pageNum < headCheckpoint.getPageNum(); pageNum++) {
                final String cpFileName = checkpointIO.tailFileName(pageNum);
                if (!dirPath.resolve(cpFileName).toFile().exists()) {
                    continue;
                }
                final Checkpoint cp = this.checkpointIO.read(cpFileName);

                logger.debug("opening tail page: {}, in: {}, with checkpoint: {}", pageNum, this.dirPath, cp.toString());

                PageIO pageIO = new MmapPageIOV2(pageNum, this.pageCapacity, this.dirPath);
                // important to NOT pageIO.open() just yet, we must first verify if it is fully acked in which case
                // we can purge it and we don't care about its integrity for example if it is of zero-byte file size.
                if (cp.isFullyAcked()) {
                    purgeTailPage(cp, pageIO);
                } else {
                    pageIO.open(cp.getMinSeqNum(), cp.getElementCount());
                    addTailPage(PageFactory.newTailPage(cp, this, pageIO));
                    diskNeeded -= (long)pageIO.getHead();
                }

                // track the seqNum as we rebuild tail pages, prevent empty pages with a minSeqNum of 0 to reset seqNum
                if (cp.maxSeqNum() > this.seqNum) {
                    this.seqNum = cp.maxSeqNum();
                }
            }

            // transform the head page into a tail page only if the headpage is non-empty
            // in both cases it will be checkpointed to track any changes in the firstUnackedPageNum when reconstructing the tail pages

            logger.debug("opening head page: {}, in: {}, with checkpoint: {}", headCheckpoint.getPageNum(), this.dirPath, headCheckpoint.toString());

            PageIO pageIO = new MmapPageIOV2(headCheckpoint.getPageNum(), this.pageCapacity, this.dirPath);
            pageIO.recover(); // optimistically recovers the head page data file and set minSeqNum and elementCount to the actual read/recovered data

            ensureDiskAvailable(diskNeeded - (long)pageIO.getHead());

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
                // but checkpoint it to update the firstUnackedPageNum if it changed
                this.headPage.checkpoint();
            } else {
                // head page is non-empty, transform it into a tail page
                this.headPage.behead();

                if (headCheckpoint.isFullyAcked()) {
                    purgeTailPage(headCheckpoint, pageIO);
                } else {
                    addTailPage(this.headPage);
                }

                // track the seqNum as we add this new tail page, prevent empty tailPage with a minSeqNum of 0 to reset seqNum
                if (headCheckpoint.maxSeqNum() > this.seqNum) {
                    this.seqNum = headCheckpoint.maxSeqNum();
                }

                // create a new empty head page
                headPageNum = headCheckpoint.getPageNum() + 1;
                newCheckpointedHeadpage(headPageNum);
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

    /**
     * delete files for the given page
     *
     * @param checkpoint the tail page {@link Checkpoint}
     * @param pageIO the tail page {@link PageIO}
     * @throws IOException
     */
    private void purgeTailPage(Checkpoint checkpoint, PageIO pageIO) throws IOException {
        try {
            pageIO.purge();
        } catch (NoSuchFileException e) { /* ignore */ }

        // we want to keep all the "middle" checkpoints between the first unacked tail page and the head page
        // to always have a contiguous sequence of checkpoints which helps figuring queue integrity. for this
        // we will remove any prepended fully acked tail pages but keep all other checkpoints between the first
        // unacked tail page and the head page. we did however purge the data file to free disk resources.

        if (this.tailPages.size() == 0) {
            // this is the first tail page and it is fully acked so just purge it
            this.checkpointIO.purge(this.checkpointIO.tailFileName(checkpoint.getPageNum()));
        }
    }

    /**
     * add a not fully-acked tail page into this queue structures and un-mmap it.
     *
     * @param page the tail {@link Page}
     * @throws IOException
     */
    private void addTailPage(Page page) throws IOException {
        this.tailPages.add(page);
        this.unreadTailPages.add(page);
        this.unreadCount += page.unreadCount();

        // for now deactivate all tail pages, we will only reactivate the first one at the end
        page.getPageIO().deactivate();
    }

    /**
     * create a new empty headpage for the given pageNum and immediately checkpoint it
     *
     * @param pageNum the page number of the new head page
     * @throws IOException
     */
    private void newCheckpointedHeadpage(int pageNum) throws IOException {
        PageIO headPageIO = new MmapPageIOV2(pageNum, this.pageCapacity, this.dirPath);
        headPageIO.create();
        this.headPage = PageFactory.newHeadPage(pageNum, this, headPageIO);
        this.headPage.forceCheckpoint();
    }

    /**
     * write a {@link Queueable} element to the queue. Note that the element will always be written and the queue full
     * condition will be checked and waited on **after** the write operation.
     *
     * @param element the {@link Queueable} element to write
     * @return the written sequence number
     * @throws IOException
     */
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
                    // here we can just purge the data file and avoid beheading since we do not need
                    // to add this fully hacked page into tailPages. a new head page will just be created.
                    // TODO: we could possibly reuse the same page file but just rename it?
                    this.headPage.purge();
                } else {
                    behead();
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
     * mark head page as read-only (behead) and add it to the tailPages and unreadTailPages collections accordingly
     * also deactivate it if it's not next-in-line for reading
     *
     * @throws IOException
     */
    private void behead() throws IOException {
        // beheading includes checkpoint+fsync if required
        this.headPage.behead();
        this.tailPages.add(this.headPage);

        if (! this.headPage.isFullyRead()) {
            if (!this.unreadTailPages.isEmpty()) {
                // there are already other unread pages so this new one is not next in line and we can deactivate
                this.headPage.deactivate();
            }
            this.unreadTailPages.add(this.headPage);
        } else {
            // it is fully read so we can deactivate
            this.headPage.deactivate();
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
            if (this.maxBytes > 0L && isMaxBytesReached()) {
                return true;
            } else {
                return (this.maxUnread > 0 && this.unreadCount >= this.maxUnread);
            }
        } finally {
            lock.unlock();
        }
    }

    private boolean isMaxBytesReached() {
        final long persistedByteSize = getPersistedByteSize();
        return ((persistedByteSize > this.maxBytes) || (persistedByteSize == this.maxBytes && !this.headPage.hasSpace(1)));
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

    /**
     * @return true if the queue is fully acked, which implies that it is fully read which works as an "empty" state.
     */
    public boolean isFullyAcked() {
        lock.lock();
        try {
            return this.tailPages.isEmpty() ? this.headPage.isFullyAcked() : false;
        } finally {
            lock.unlock();
        }
    }

    /**
     * guarantee persistence up to a given sequence number.
     *
     * @param seqNum the element sequence number upper bound for which persistence should be guaranteed (by fsync'ing)
     * @throws IOException
     */
    public void ensurePersistedUpto(long seqNum) throws IOException{
        lock.lock();
        try {
            this.headPage.ensurePersistedUpto(seqNum);
        } finally {
            lock.unlock();
        }
    }

    /**
     * non-blocking queue read
     *
     * @param limit read the next batch of size up to this limit. the returned batch size can be smaller than the requested limit if fewer elements are available
     * @return {@link Batch} the batch containing 1 or more element up to the required limit or null of no elements were available
     * @throws IOException
     */
    public synchronized Batch nonBlockReadBatch(int limit) throws IOException {
        lock.lock();
        try {
            Page p = nextReadPage();
            return (isHeadPage(p) && p.isFullyRead()) ? null : readPageBatch(p, limit, 0L);
        } finally {
            lock.unlock();
        }
    }

    /**
     *
     * @param limit size limit of the batch to read. returned {@link Batch} can be smaller.
     * @param timeout the maximum time to wait in milliseconds on write operations
     * @return the read {@link Batch} or null if no element upon timeout
     * @throws IOException
     */
    public synchronized Batch readBatch(int limit, long timeout) throws IOException {
        lock.lock();
        try {
            return readPageBatch(nextReadPage(), limit, timeout);
        } finally {
            lock.unlock();
        }
    }

    /**
     * read a {@link Batch} from the given {@link Page}. If the page is a head page, try to maximize the
     * batch size by waiting for writes.
     * @param p the {@link Page} to read from.
     * @param limit size limit of the batch to read.
     * @param timeout  the maximum time to wait in milliseconds on write operations.
     * @return {@link Batch} with read elements or null if nothing was read
     * @throws IOException
     */
    private Batch readPageBatch(Page p, int limit, long timeout) throws IOException {
        int left = limit;
        final List<byte[]> elements = new ArrayList<>(limit);

        // NOTE: the tricky thing here is that upon entering this method, if p is initially a head page
        // it could become a tail page upon returning from the notEmpty.await call.
        long firstSeqNum = -1L;
        while (left > 0) {
            if (isHeadPage(p) && p.isFullyRead()) {
                boolean elapsed;
                // a head page is fully read but can be written to so let's wait for more data
                try {
                    elapsed = !notEmpty.await(timeout, TimeUnit.MILLISECONDS);
                } catch (InterruptedException e) {
                    // set back the interrupted flag
                    Thread.currentThread().interrupt();
                    break;
                }

                if ((elapsed && p.isFullyRead()) || isClosed()) {
                    break;
                }
            }

            if (! p.isFullyRead()) {
                boolean wasFull = isFull();

                final SequencedList<byte[]> serialized = p.read(left);
                int n = serialized.getElements().size();
                assert n > 0 : "page read returned 0 elements";
                elements.addAll(serialized.getElements());
                if (firstSeqNum == -1L) {
                    firstSeqNum = serialized.getSeqNums().get(0);
                }

                this.unreadCount -= n;
                left -= n;

                if (wasFull) {
                    notFull.signalAll();
                }
            }

            if (isTailPage(p) && p.isFullyRead()) {
                break;
            }
        }

        if (isTailPage(p) && p.isFullyRead()) {
            removeUnreadPage(p);
        }

        return new Batch(elements, firstSeqNum, this);
    }

    /**
     * perform a binary search through tail pages to find in which page this seqNum falls into
     *
     * @param seqNum the sequence number to search for in the tail pages
     * @return Index of the found {@link Page} in {@link #tailPages}
     */
    private int binaryFindPageForSeqnum(final long seqNum) {
        int lo = 0;
        int hi = this.tailPages.size() - 1;
        while (lo <= hi) {
            final int mid = lo + (hi - lo) / 2;
            final Page p = this.tailPages.get(mid);
            final long pMinSeq = p.getMinSeqNum();
            if (seqNum < pMinSeq) {
                hi = mid - 1;
            } else if (seqNum >= pMinSeq + (long) p.getElementCount()) {
                lo = mid + 1;
            } else {
                return mid;
            }
        }
        throw new IllegalArgumentException(
            String.format("Sequence number %d not found in any page", seqNum)
        );
    }

    /**
     * ack a list of seqNums that are assumed to be all part of the same page, leveraging the fact that batches are also created from
     * same-page elements. A fully acked page will trigger a checkpoint for that page. Also if a page has more than checkpointMaxAcks
     * acks since last checkpoint it will also trigger a checkpoint.
     *
     * @param firstAckSeqNum First Sequence Number to Ack
     * @param ackCount Number of Elements to Ack
     * @throws IOException
     */
    public void ack(final long firstAckSeqNum, final int ackCount) throws IOException {
        // as a first implementation we assume that all batches are created from the same page
        lock.lock();
        try {
            if (containsSeq(headPage, firstAckSeqNum)) {
                this.headPage.ack(firstAckSeqNum, ackCount, this.checkpointMaxAcks);
            } else {
                final int resultIndex = binaryFindPageForSeqnum(firstAckSeqNum);
                if (tailPages.get(resultIndex).ack(firstAckSeqNum, ackCount, this.checkpointMaxAcks)) {
                    this.tailPages.remove(resultIndex);
                    notFull.signalAll();
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

    /**
     *  deserialize a byte array into the required element class.
     *
     * @param bytes the byte array to deserialize
     * @return {@link Queueable} the deserialized byte array into the required Queueable interface implementation concrete class
     */
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

    /**
     * return the {@link Page} for the next read operation.
     * @return {@link Page} will be either a read-only tail page or the head page.
     */
    public Page nextReadPage() {
        lock.lock();
        try {
            // look at head page if no unreadTailPages
            return (this.unreadTailPages.isEmpty()) ?  this.headPage : this.unreadTailPages.get(0);
        } finally {
            lock.unlock();
        }
    }

    private void removeUnreadPage(Page p) {
        if (! this.unreadTailPages.isEmpty()) {
            Page firstUnread = this.unreadTailPages.get(0);
            assert p.pageNum <= firstUnread.pageNum : String.format("fully read pageNum=%d is greater than first unread pageNum=%d", p.pageNum, firstUnread.pageNum);
            if (firstUnread == p) {
                // it is possible that when starting to read from a head page which is beheaded will not be inserted in the unreadTailPages list
                this.unreadTailPages.remove(0);
            }
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

    /**
     * @param p the {@link Page} to verify if it is the head page
     * @return true if the given {@link Page} is the head page
     */
    private boolean isHeadPage(Page p) {
        return p == this.headPage;
    }

    /**
     * @param p the {@link Page} to verify if it is a tail page
     * @return true if the given {@link Page} is a tail page
     */
    private boolean isTailPage(Page p) {
        return !isHeadPage(p);
    }

    private void ensureDiskAvailable(final long diskNeeded) throws IOException {
        if (!FsUtil.hasFreeSpace(this.dirPath, diskNeeded)) {
            throw new IOException("Not enough free disk space available to allocate persisted queue.");
        }
    }

    private static boolean containsSeq(final Page page, final long seqNum) {
        final long pMinSeq = page.getMinSeqNum();
        final long pMaxSeq = pMinSeq + (long) page.getElementCount();
        return seqNum >= pMinSeq && seqNum < pMaxSeq;
    }
}
