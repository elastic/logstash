package org.logstash.ackedqueue;

import org.logstash.common.io.ElementIO;

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

    private final ElementIO io;
    private final String dirPath;

    // TODO: I really don't like the idea of passing a dummy ElementIO object for the sake of holding a reference to the
    // concrete class for later invoking open() and create() in the Page
    public Queue(String dirPath, ElementIO io) {
        this.io = io;
        this.dirPath = dirPath;

        this.tailPages = new ArrayList<>();
    }

    // moved queue opening logic in open() method until wehave something in place to used in-memory checkpoints for testing
    // because for now we need to pass a Queue instance to the Page and we don't want to trigger a Queue recovery when
    // testing Page
    public void open() throws IOException {
        final int headPageNum;
        Checkpoint headCheckpoint = Checkpoint.read("checkpoint.head");

        if (headCheckpoint == null) {
            this.seqNum = 0;
            headPageNum = 0;
        } else {
            // handle all tail pages upto but excluding the head page
            for (int pageNum = headCheckpoint.getFirstUnackedPageNum(); pageNum < headCheckpoint.getPageNum(); pageNum++) {
                Checkpoint tailCheckpoint = Checkpoint.read("checkpoint." + pageNum); // TODO: add directory path handling

                BeheadedPage tailPage = new BeheadedPage(tailCheckpoint, this);
                this.tailPages.add(tailPage);
            }

            // handle the head page
            // transform the head page into a beheaded tail page
            BeheadedPage beheadedHeadPage = new BeheadedPage(headCheckpoint, this);
            this.tailPages.add(beheadedHeadPage);

            beheadedHeadPage.checkpoint(headCheckpoint.getFirstUnackedSeqNum());
            headPageNum = headCheckpoint.getPageNum() + 1;
        }

        headPage = new HeadPage(headPageNum, this);
        headPage.checkpoint(headCheckpoint.getFirstUnackedSeqNum());

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
    public void ensurePersistedUpto(long seqNum) {
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

    public void ack(long[] seqNums) {
        // as a first implementation we assume that all batches are created from the same page
        // so we will avoid multi pages acking here for now

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
            headPage.checkpoint(firstUnackedPageNum());
            // TODO: delete/purge using toDelete list
        }
    }

    public long nextSeqNum() {
        return seqNum += 1;
    }

    public ElementIO getIo() {
        return io;
    }

    public String getDirPath() {
        return dirPath;
    }

    private int firstUnackedPageNum() {
        if (this.tailPages.isEmpty()) {
            return headPage.getPageNum();
        }
        return this.tailPages.get(0).getPageNum();
    }

}
