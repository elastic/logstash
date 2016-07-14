package org.logstash.ackedqueue;

import org.logstash.common.io.CheckpointIO;
import org.logstash.common.io.PageIO;

import java.io.IOException;
import java.nio.file.NoSuchFileException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;


// TODO: Notes
//
// - time-based fsync
//
// - tragic errors handling
//   - what errors cause whole queue to be broken
//   - where to put try/catch for these errors


public class Queue {
    protected long seqNum;
    protected HeadPage headPage;
    protected final List<BeheadedPage> tailPages;

    private final Settings settings;

    private final CheckpointIO checkpointIO;
    private final ElementDeserialiser deserialiser;

    // TODO: I really don't like the idea of passing a dummy PageIO object for the sake of holding a reference to the
    // concrete class for later invoking open() and create() in the Page
    public Queue(Settings settings) {
        this.settings = settings;
        this.tailPages = new ArrayList<>();
        this.checkpointIO = settings.getCheckpointIOFactory().build(settings.getDirPath());
        this.deserialiser = settings.getElementDeserialiser();
    }

    // moved queue opening logic in open() method until we have something in place to used in-memory checkpoints for testing
    // because for now we need to pass a Queue instance to the Page and we don't want to trigger a Queue recovery when
    // testing Page
    public void open() throws IOException {
        final int headPageNum;

        Checkpoint headCheckpoint;
        try {
            headCheckpoint = checkpointIO.read("checkpoint.head");
        } catch (NoSuchFileException e) {
            headCheckpoint = null;
        }

        if (headCheckpoint == null) {
            this.seqNum = 0;
            headPageNum = 0;
        } else {
            // handle all tail pages upto but excluding the head page
            for (int pageNum = headCheckpoint.getFirstUnackedPageNum(); pageNum < headCheckpoint.getPageNum(); pageNum++) {
                Checkpoint tailCheckpoint = checkpointIO.read("checkpoint." + pageNum);

                if (tailCheckpoint == null) {
                    throw new IOException(String.format("checkpoint.%d not found", pageNum));
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

            // handle the head page
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
        }

        PageIO pageIO = settings.getPageIOFactory().build(headPageNum, this.settings.getCapacity(), this.settings.getDirPath());
        this.headPage = new HeadPage(headPageNum, this, pageIO);

        // we can let the headPage get its first unacked page num via the tailPages
        this.headPage.checkpoint();

        // TODO: do directory traversal and cleanup lingering pages? could be a background operations to not delay queue start?
    }

    // @param element the Queueable object to write to the queue
    // @return long written sequence number
    public synchronized long write(Queueable element) throws IOException {
        element.setSeqNum(nextSeqNum());
        byte[] data = element.serialize();

        if (! this.headPage.hasSpace(data.length)) {
            // beheading includes checkpoint+fsync if required
            BeheadedPage tailPage = this.headPage.behead();

            this.tailPages.add(tailPage);

            // create new head page
            int headPageNum = tailPage.pageNum + 1;
            PageIO pageIO = this.settings.getPageIOFactory().build(headPageNum, this.settings.getCapacity(), this.settings.getDirPath());
            this.headPage = new HeadPage(headPageNum, this, pageIO);
            this.headPage.checkpoint();

            // TODO: redo this.headPage.hasSpace(data.length) to make sure data is not greater than page size?
        }

        this.headPage.write(data, element);

        return element.getSeqNum();
    }

    // @param seqNum the element sequence number upper bound for which persistence should be garanteed (by fsync'int)
    public synchronized void ensurePersistedUpto(long seqNum) throws IOException{
         this.headPage.ensurePersistedUpto(seqNum);
    }

    public synchronized Batch readBatch(int limit) throws IOException {
        Page p = firstUnreadPage();
        if (p == null) {
            // TODO: add blocking + signaling with the write side for a blocking read
            return null;
        }

        return p.readBatch(limit);
    }

    public synchronized void ack(List<Long> seqNums) throws IOException {
        // as a first implementation we assume that all batches are created from the same page
        // so we will avoid multi pages acking here for now

        Page ackPage = null;

        // first the page to ack by travesing from oldest tail page
        long firstAckSeqNum = seqNums.get(0);
        for (Page p : this.tailPages) {
            if (p.getMinSeqNum() > 0 && firstAckSeqNum >= p.getMinSeqNum() && firstAckSeqNum < p.getMinSeqNum() + p.getElementCount()) {
                ackPage = p;
                break;
            }
        }

        // if not found it must be in head
        if (ackPage == null) {
            ackPage = this.headPage;

            assert this.headPage.getMinSeqNum() > 0 && firstAckSeqNum >= this.headPage.getMinSeqNum() && firstAckSeqNum < this.headPage.getMinSeqNum() + this.headPage.getElementCount():
                    String.format("seqNum=%d is not in head page with minSeqNum=%d", firstAckSeqNum, this.headPage.getMinSeqNum());
        }

        ackPage.ack(seqNums);

        // cleanup fully acked pages

        Iterator<BeheadedPage> i = this.tailPages.iterator();
        boolean changed = false;
        List<BeheadedPage> toDelete = new ArrayList<>();

        // TODO: since acking is within a single page, we don't really need to traverse whole tail pages, we can optimize this

        while (i.hasNext()) {
            BeheadedPage p = i.next();
            if (p.isFullyAcked()) {
                i.remove();
                changed = true;
                toDelete.add(p);
            } else {
                break;
            }
        }

        if (changed) {
            this.headPage.checkpoint();

            for (BeheadedPage p : toDelete) {
                p.purge();
            }
        }
    }

    private long nextSeqNum() {
        return this.seqNum += 1;
    }

    public CheckpointIO getCheckpointIO() {
        return this.checkpointIO;
    }

    public ElementDeserialiser getDeserialiser() {
        return this.deserialiser;
    }

    public Page firstUnreadPage() throws IOException {
        // TODO: avoid tailPages traversal below by keeping tab of the last read tail page

        for (Page p : this.tailPages) {
            if (! p.isFullyRead()) {
                return p;
            }

            // deactivate all fully read page. calling deactivate on a deactivated page is harmless
            p.getPageIO().deactivate();
        }

        if (! this.headPage.isFullyRead()) {
            return this.headPage;
        }

        return null;
    }

    protected int firstUnackedPageNum() {
        if (this.tailPages.isEmpty()) {
            return this.headPage.getPageNum();
        }
        return this.tailPages.get(0).getPageNum();
    }

}
