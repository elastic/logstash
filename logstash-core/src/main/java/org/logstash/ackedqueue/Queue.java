package org.logstash.ackedqueue;

import org.logstash.common.io.CheckpointIO;
import org.logstash.common.io.PageIO;

import java.io.Closeable;
import java.io.IOException;
import java.nio.file.NoSuchFileException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Iterator;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;


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

    // first non-fully-read tail page num
    private int firstUnreadTailPageNum;

    private final Settings settings;

    private final CheckpointIO checkpointIO;
    private final ElementDeserialiser deserialiser;
    private final AtomicBoolean closed;

    public Queue(Settings settings) {
        this.settings = settings;
        this.tailPages = new ArrayList<>();
        this.firstUnreadTailPageNum = 0;
        this.checkpointIO = settings.getCheckpointIOFactory().build(settings.getDirPath());
        this.deserialiser = settings.getElementDeserialiser();
        this.closed = new AtomicBoolean(true); // not yet opened
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

                PageIO pageIO = settings.getPageIOFactory().build(pageNum, this.settings.getCapacity(), this.settings.getDirPath());
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
            }

            // transform the head page into a beheaded tail page
            PageIO pageIO = settings.getPageIOFactory().build(headCheckpoint.getPageNum(), this.settings.getCapacity(), this.settings.getDirPath());
            BeheadedPage beheadedHeadPage = new BeheadedPage(headCheckpoint, this, pageIO);

            // track the seqNum as we rebuild tail pages
            if (beheadedHeadPage.maxSeqNum() > this.seqNum) {
                // prevent empty beheadedHeadPage with a minSeqNum of 0 to reset seqNum
                this.seqNum = beheadedHeadPage.maxSeqNum();
            }

            this.tailPages.add(beheadedHeadPage);

            beheadedHeadPage.checkpoint();
            headPageNum = headCheckpoint.getPageNum() + 1;

            // at this point the first page with elements to read from is necessarily the first tail page.
            this.firstUnreadTailPageNum = this.tailPages.get(0).getPageNum();
        }

        // create new head page
        PageIO pageIO = settings.getPageIOFactory().build(headPageNum, this.settings.getCapacity(), this.settings.getDirPath());
        this.headPage = new HeadPage(headPageNum, this, pageIO);
        this.headPage.checkpoint();

        // TODO: here do directory traversal and cleanup lingering pages? could be a background operations to not delay queue start?

        this.closed.set(false);
    }

    // @param element the Queueable object to write to the queue
    // @return long written sequence number
    public synchronized long write(Queueable element) throws IOException {
        element.setSeqNum(nextSeqNum());
        byte[] data = element.serialize();

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
            PageIO pageIO = this.settings.getPageIOFactory().build(headPageNum, this.settings.getCapacity(), this.settings.getDirPath());
            this.headPage = new HeadPage(headPageNum, this, pageIO);
            this.headPage.checkpoint();
        }

        this.headPage.write(data, element);

        // if the queue was empty before write, notifyAll blocking reachBatch threads that queue is now non-empty
        if (wasEmpty) {
            notifyAll();
        }

        return element.getSeqNum();
    }

    // @param seqNum the element sequence number upper bound for which persistence should be garanteed (by fsync'ing)
    public synchronized void ensurePersistedUpto(long seqNum) throws IOException{
         this.headPage.ensurePersistedUpto(seqNum);
    }

    // non-blockin queue read
    // @param limit read the next bach of size up to this limit. the returned batch size can be smaller than than the requested limit if fewer elements are available
    // @return Batch the batch containing 1 or more element up to the required limit or null of no elements were available
    public synchronized Batch nonBlockReadBatch(int limit) throws IOException {
        Page p = firstUnreadPage();
        if (p == null) {
            return null;
        }

        return p.readBatch(limit);
     }


    // blocking readBatch notes:
    //   the queue close() notifies all pending blocking read so that they unblock if the queue is being closed.
    //   this means that all blocking read methods need to verify for the queue close condition.
    //
    // blocking queue read until elements are available for read
    // @param limit read the next bach of size up to this limit. the returned batch size can be smaller than than the requested limit if fewer elements are available
    // @return Batch the batch containing 1 or more element up to the required limit or null if no elements were available
    public synchronized Batch readBatch(int limit) throws IOException {
        Page p;

        while ((p = firstUnreadPage()) == null && !isClosed()) {
            try {
                wait();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                // TODO: what should we do with an InterruptedException here?
                throw new RuntimeException("blocking readBatch InterruptedException", e);
            }
        }

        // need to check for close since it is a condition for exiting the while loop
        return isClosed() ? null : p.readBatch(limit);
    }

    // blocking queue read until elements are available for read or the given timeout is reached.
    // @param limit read the next bach of size up to this limit. the returned batch size can be smaller than than the requested limit if fewer elements are available
    // @param timeout the maximum time to wait in milliseconds
    // @return Batch the batch containing 1 or more element up to the required limit or null if no elements were available
    public synchronized Batch readBatch(int limit, long timeout) throws IOException {
        Page p;

        // wait only if queue is empty
        if ((p = firstUnreadPage()) == null) {
            try {
                wait(timeout);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                // TODO: what should we do with an InterruptedException here?
                throw new RuntimeException("timeout blocking readBatch InterruptedException", e);
            }

            // if after returnining from wait queue is still empty, or the queue was closed return null
            if ((p = firstUnreadPage()) == null || isClosed()) {
                return null;
            }
        }

        return p.readBatch(limit);
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

    public synchronized void ack(List<Long> seqNums) throws IOException {
        // as a first implementation we assume that all batches are created from the same page
        // so we will avoid multi pages acking here for now

        // find the page to ack by travesing from oldest tail page
        long firstAckSeqNum = seqNums.get(0);

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
     }

    public CheckpointIO getCheckpointIO() {
        return this.checkpointIO;
    }

    public ElementDeserialiser getDeserialiser() {
        return this.deserialiser;
    }

    public synchronized void close() throws IOException {
        // TODO: review close strategy and exception handling and resiliency of first closing tail pages if crash in the middle

        // for now the AtomicBoolean close is not necessary since the close() method is synchronized but
        // this may change and it'll be future proof
        if (closed.getAndSet(true) == false) {
            // TODO: not sure if we need to do this here since the headpage close will also call ensurePersited
            ensurePersistedUpto(this.seqNum);

            for (BeheadedPage p : this.tailPages) {
                p.close();
            }
            this.headPage.close();

            notifyAll();
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
