package org.logstash.ackedqueue;

import com.logstash.Event;

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
    private List<BeheadedPage> tailPages;

    public Queue(String dirPath) {
        this.tailPages = new ArrayList<>();

        final int headPageNum;
        Checkpoint headCheckpoint = Checkpoint.read("checkpoint.head");

        if (headCheckpoint == null) {
            this.seqNum = 0;
            headPageNum = 0;
        } else {
            // handle all tail pages upto but excluding the head page
            for (int pageNum = headCheckpoint.firstUnackedPageNum; pageNum < headCheckpoint.pageNum; pageNum++) {
                // TODO: add directory path handling
                Checkpoint tailCheckpoint = Checkpoint.read("checkpoint." + pageNum);

                BeheadedPage tailPage = new BeheadedPage(tailCheckpoint);
                this.tailPages.add(tailPage);
            }

            // handle the head page
            // transform the head page into a beheaded tail page
            BeheadedPage beheadedHeadPage = new BeheadedPage(headCheckpoint);
            this.tailPages.add(beheadedHeadPage);

            beheadedHeadPage.checkpoint(headCheckpoint.firstUnackedPageNum);
            headPageNum = headCheckpoint.pageNum + 1;
        }

        headPage = new HeadPage(headPageNum);
        headPage.checkpoint(headCheckpoint.firstUnackedPageNum);

        // TODO: do directory traversal and cleanup lingering pages
    }

    // @param event the Event to write to the queue
    // @return long written sequence number
    public long write(Event event) {

        // TODO: assign next seqNum to Event

        // TODO: serialize Event to byte[]

        byte[] data = {};  // placeholder for serialized event

        if (! headPage.hasSpace(data.length)) {
            // TODO:
            //
            // migrate current head to a beheaded page
            // checkpoint beheaded page
            // create new head page
            // checkpoint new head page
        }

        headPage.write(data, event);

        return 0; // will return event assigned seqNum
    }

    // @param seqNum the event sequence number upper bound for which persistence should be garanteed (by fsync'int)
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

    private int firstUnackedPageNum() {
        if (this.tailPages.isEmpty()) {
            return headPage.getPageNum();
        }
        return this.tailPages.get(0).getPageNum();
    }

}
