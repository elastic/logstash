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
    protected final List<BeheadedPage> tailPages;
    protected long unreadCount;

    // first non-fully-read tail page num
    private int firstUnreadTailPageNum;

    private final CheckpointIO checkpointIO;
    private final PageIOFactory pageIOFactory;
    private final int capacity;
    private final String dirPath;

    private final AtomicBoolean closed;

    // deserialization
    private final Class elementClass;
    private final Method deserializeMethod;

    // thread safety
    final Lock lock = new ReentrantLock();
    final Condition notFull  = lock.newCondition();
    final Condition notEmpty = lock.newCondition();

    public Queue(Settings settings) {
        this(settings.getDirPath(), settings.getCapacity(), settings.getCheckpointIOFactory().build(settings.getDirPath()), settings.getPageIOFactory(), settings.getElementClass());
    }

    public Queue(String dirPath, int capacity, CheckpointIO checkpointIO, PageIOFactory pageIOFactory, Class elementClass) {
        this.dirPath = dirPath;
        this.capacity = capacity;
        this.checkpointIO = checkpointIO;
        this.pageIOFactory = pageIOFactory;
        this.elementClass = elementClass;
        this.tailPages = new ArrayList<>();
        this.firstUnreadTailPageNum = 0;
        this.closed = new AtomicBoolean(true); // not yet opened
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

                PageIO pageIO = this.pageIOFactory.build(pageNum, this.capacity, this.dirPath);
                BeheadedPage tailPage = new BeheadedPage(tailCheckpoint, this, pageIO);

                // if this page is not the first tail page, deactivate it
                // we keep the first tail page activated since we know the next read operation will be in that one
                if (pageNum > headCheckpoint.getFirstUnackedPageNum()) {
                    pageIO.deactivate();
                }

                // track the seqNum as we rebuild tail pages
                if (tailPage.maxSeqNum() > this.seqNum) {
                    // prevent empty pages with a minSeqNum of 0 to reset seqNum
                    this.seqNum = tailPage.maxSeqNum();
                }

                this.tailPages.add(tailPage);
                this.unreadCount += tailPage.unreadCount();
            }

            // transform the head page into a beheaded tail page
            PageIO pageIO = this.pageIOFactory.build(headCheckpoint.getPageNum(), this.capacity, this.dirPath);
            BeheadedPage beheadedHeadPage = new BeheadedPage(headCheckpoint, this, pageIO);

            // track the seqNum as we rebuild tail pages
            if (beheadedHeadPage.maxSeqNum() > this.seqNum) {
                // prevent empty beheadedHeadPage with a minSeqNum of 0 to reset seqNum
                this.seqNum = beheadedHeadPage.maxSeqNum();
            }

            this.tailPages.add(beheadedHeadPage);
            this.unreadCount += beheadedHeadPage.unreadCount();

            beheadedHeadPage.checkpoint();
            headPageNum = headCheckpoint.getPageNum() + 1;

            // at this point the first page with elements to read from is necessarily the first tail page.
            this.firstUnreadTailPageNum = this.tailPages.get(0).getPageNum();
        }

        // create new head page
        PageIO pageIO = this.pageIOFactory.build(headPageNum, this.capacity, this.dirPath);
        this.headPage = new HeadPage(headPageNum, this, pageIO);
        this.headPage.checkpoint();

        // TODO: here do directory traversal and cleanup lingering pages? could be a background operations to not delay queue start?

        this.closed.set(false);
    }

    // @param element the Queueable object to write to the queue
    // @return long written sequence number
    public long write(Queueable element) throws IOException {
        element.setSeqNum(nextSeqNum());
        byte[] data = element.serialize();

        lock.lock();
        try {
            if (! this.headPage.hasCapacity(data.length)) {
                throw new IOException("data to be written is bigger than page capacity");
            }

            boolean wasEmpty = (firstUnreadPage() == null);

            // create a new head page if the current does not have suffient space left for data to be written
            if (! this.headPage.hasSpace(data.length)) {
                // beheading includes checkpoint+fsync if required
                BeheadedPage tailPage = this.headPage.behead();

                this.tailPages.add(tailPage);

                // create new head page
                int headPageNum = tailPage.pageNum + 1;
                PageIO pageIO = this.pageIOFactory.build(headPageNum, this.capacity, this.dirPath);
                this.headPage = new HeadPage(headPageNum, this, pageIO);
                this.headPage.checkpoint();
            }

            this.headPage.write(data, element);
            this.unreadCount++;

            // if the queue was empty before write, signal non emptiness
            if (wasEmpty) { notEmpty.signal(); }
        } finally {
            lock.unlock();
        }

        return element.getSeqNum();
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

            Batch b = p.readBatch(limit);
            this.unreadCount -= b.size();
            return b;
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
    // @return Batch the batch containing 1 or more element up to the required limit or null if no elements were available
    public Batch readBatch(int limit) throws IOException {
        Page p;

        lock.lock();
        try {
            while ((p = firstUnreadPage()) == null && !isClosed()) {
                try {
                    notEmpty.await();
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    // TODO: what should we do with an InterruptedException here?
                    throw new RuntimeException("blocking readBatch InterruptedException", e);
                }
            }

            // need to check for close since it is a condition for exiting the while loop
            if (isClosed()) { return null; }

            Batch b = p.readBatch(limit);
            this.unreadCount -= b.size();
            return b;
        } finally {
            lock.unlock();
        }
    }

    // blocking queue read until elements are available for read or the given timeout is reached.
    // @param limit read the next batch of size up to this limit. the returned batch size can be smaller than than the requested limit if fewer elements are available
    // @param timeout the maximum time to wait in milliseconds
    // @return Batch the batch containing 1 or more element up to the required limit or null if no elements were available
    public Batch readBatch(int limit, long timeout) throws IOException {
        Page p;

        lock.lock();
        try {
            // wait only if queue is empty
            if ((p = firstUnreadPage()) == null) {
                try {
                    notEmpty.await(timeout, TimeUnit.MILLISECONDS);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    // TODO: what should we do with an InterruptedException here?
                    throw new RuntimeException("timeout blocking readBatch InterruptedException", e);
                }

                // if after returnining from wait queue is still empty, or the queue was closed return null
                if ((p = firstUnreadPage()) == null || isClosed()) { return null; }
            }

            Batch b = p.readBatch(limit);
            this.unreadCount -= b.size();
            return b;
        } finally {
            lock.unlock();
        }
    }

    private static class TailPageResult {
        public BeheadedPage page;
        public int index;

        public TailPageResult(BeheadedPage page, int index) {
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
            BeheadedPage p = this.tailPages.get(mid);

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
            BeheadedPage p = this.tailPages.get(i);
            if (p.getMinSeqNum() > 0 && seqNum >= p.getMinSeqNum() && seqNum < p.getMinSeqNum() + p.getElementCount()) {
                return new TailPageResult(p, i);
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
            TailPageResult result = (this.tailPages.size() > 3) ? binaryFindPageForSeqnum(firstAckSeqNum) : linearFindPageForSeqnum(firstAckSeqNum);

            if (result == null) {
                // if not found then it is in head page
                assert this.headPage.getMinSeqNum() > 0 && firstAckSeqNum >= this.headPage.getMinSeqNum() && firstAckSeqNum < this.headPage.getMinSeqNum() + this.headPage.getElementCount():
                        String.format("seqNum=%d is not in head page with minSeqNum=%d", firstAckSeqNum, this.headPage.getMinSeqNum());
                this.headPage.ack(seqNums);
            } else {
                result.page.ack(seqNums);

                // cleanup fully acked tail page
                if (result.page.isFullyAcked()) {
                    this.tailPages.remove(result.index);
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

                for (BeheadedPage p : this.tailPages) { p.close(); }
                this.headPage.close();

                notEmpty.signalAll();
            } finally {
                lock.unlock();
            }
        }
    }

    protected Page firstUnreadPage() throws IOException {
        BeheadedPage firstUnreadTailPage = getTailPage(firstUnreadTailPageNum);

        while (firstUnreadTailPage != null && firstUnreadTailPage.isFullyRead()) {
            // deactivate all fully read page. calling deactivate on a deactivated page is harmless
            firstUnreadTailPage.getPageIO().deactivate();

            // advance to next tail page
            firstUnreadTailPageNum++;
            firstUnreadTailPage = getTailPage(firstUnreadTailPageNum);
        }

        if (firstUnreadTailPage != null) {
            return firstUnreadTailPage;
        }

        // at this point either there are no tail pages or all tail pages are fully read, look in the head page
        if (! this.headPage.isFullyRead()) {
            return this.headPage;
        }

        return null;
    }

    // @return the TailPage for the given pageNum or null if pageNum is out of bound or there are no tail pages
    private BeheadedPage getTailPage(int pageNum) {
        if (this.tailPages.isEmpty()) {
            return null;
        }

        int firstPageNum = this.tailPages.get(0).getPageNum();
        int i = pageNum - firstPageNum;
        return (i >= this.tailPages.size()) ? null : this.tailPages.get(i);
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
