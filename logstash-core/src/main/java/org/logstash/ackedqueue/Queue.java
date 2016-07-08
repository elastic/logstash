package org.logstash.ackedqueue;

import org.logstash.common.io.CheckpointIO;
import org.logstash.common.io.PageIO;

import java.io.IOException;
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
    private long seqNum;
    private HeadPage headPage;
    private final List<BeheadedPage> tailPages;

    private final Settings settings;

    private final CheckpointIO checkpointIO;

    // TODO: I really don't like the idea of passing a dummy PageIO object for the sake of holding a reference to the
    // concrete class for later invoking open() and create() in the Page
    public Queue(Settings settings) {
        this.settings = settings;
        this.tailPages = new ArrayList<>();
        this.checkpointIO = settings.getCheckpointIOFactory().build(settings.getDirPath());
    }

    // moved queue opening logic in open() method until we have something in place to used in-memory checkpoints for testing
    // because for now we need to pass a Queue instance to the Page and we don't want to trigger a Queue recovery when
    // testing Page
    public void open() throws IOException {
        final int headPageNum;

        Checkpoint headCheckpoint = checkpointIO.read("checkpoint.head");

        if (headCheckpoint == null) {
            this.seqNum = 0;
            headPageNum = 0;
        } else {
            // handle all tail pages upto but excluding the head page
            for (int pageNum = headCheckpoint.getFirstUnackedPageNum(); pageNum < headCheckpoint.getPageNum(); pageNum++) {
                Checkpoint tailCheckpoint = checkpointIO.read("checkpoint." + pageNum);
                if (tailCheckpoint != null) {
                    PageIO pageIO = settings.getPageIOFactory().build(this.settings.getCapacity(), this.settings.getDirPath());
                    BeheadedPage tailPage = new BeheadedPage(tailCheckpoint, this, pageIO);
                    this.tailPages.add(tailPage);
                }
            }

            // handle the head page
            // transform the head page into a beheaded tail page
            PageIO pageIO = settings.getPageIOFactory().build(this.settings.getCapacity(), this.settings.getDirPath());
            BeheadedPage beheadedHeadPage = new BeheadedPage(headCheckpoint, this, pageIO);
            this.tailPages.add(beheadedHeadPage);

            beheadedHeadPage.checkpoint();
            headPageNum = headCheckpoint.getPageNum() + 1;
        }

        PageIO pageIO = settings.getPageIOFactory().build(this.settings.getCapacity(), this.settings.getDirPath());
        headPage = new HeadPage(headPageNum, this, pageIO);

        // we can let the headPage get its first unacked page num via the tailPages
        headPage.checkpoint();

        // TODO: do directory traversal and cleanup lingering pages
    }

    // @param element the Queueable object to write to the queue
    // @return long written sequence number
    public long write(Queueable element) {

        // TODO: assign next seqNum to element

        // TODO: serialize element to byte[]

        byte[] data = element.serialize();

        if (! headPage.hasSpace(data.length)) {
            // TODO:
            //
            // migrate current head to a beheaded page
            // checkpoint beheaded page
            // create new head page
            // checkpoint new head page
        }

        headPage.write(data, element);

        return 0; // will return element assigned seqNum
    }

    // @param seqNum the element sequence number upper bound for which persistence should be garanteed (by fsync'int)
    public void ensurePersistedUpto(long seqNum) throws IOException{
         headPage.ensurePersistedUpto(seqNum);
    }

    public Batch readBatch(int limit) {

        // TODO: avoid tailPages traversal below by keeping tab of the last read tail page

        for (Page p : this.tailPages) {
            if (! p.isFullyRead()) {
                return p.readBatch(limit);
            }
        }

        if (! headPage.isFullyRead()) {
            return headPage.readBatch(limit);
        }

        // at this point there is no new data to read

        // TODO: add blocking + signaling with the write side for a blocking read

        // TODO: return null if there is nothing to read or return an empty batch?
        // we could have an empty batch constant like EMPTY_BATCH = new Batch()
        return null;
    }

    public void ack(long[] seqNums) throws IOException {
        // as a first implementation we assume that all batches are created from the same page
        // so we will avoid multi pages acking here for now

        // remove 'throws IOException'
        // TODO: find page containing seqNums
        //   - check the count/empty pages
        Page ackPage = null;
        ackPage.ack(seqNums);

        // cleanup fully acked pages

        Iterator i = this.tailPages.iterator();
        boolean changed = false;
        List<Page> toDelete = new ArrayList<>();

        while(i.hasNext()) {
            Page p = (Page)i.next();
            if (p.isFullyAcked()) {
                i.remove();
                changed = true;
                toDelete.add(p);
            } else {
                break;
            }
        }

        if (changed) {
            headPage.checkpoint();
            // TODO: delete/purge using toDelete list
        }
    }

    public long nextSeqNum() {
        return seqNum += 1;
    }

    public CheckpointIO getCheckpointIO() {
        return checkpointIO;
    }

//    public PageIO getIo() {
//        return io;
//    }
//
//    public String getDirPath() {
//        return dirPath;
//    }

    protected int firstUnackedPageNum() {
        if (this.tailPages.isEmpty()) {
            return headPage.getPageNum();
        }
        return this.tailPages.get(0).getPageNum();
    }

}
