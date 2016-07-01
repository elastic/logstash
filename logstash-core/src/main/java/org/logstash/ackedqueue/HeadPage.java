package org.logstash.ackedqueue;

import com.logstash.Event;

public class HeadPage extends Page {

    public HeadPage(int pageNum) {
        // TODO:
        // create new page file
        // write a version number as first byte(s)
        // write header? (some debugging info, logstash version?, queue version, etc)
    }

    public boolean hasSpace(int byteSize) {
        // TODO:
        return true;
    }

    public void write(byte[] bytes, Event event) {
        // TODO: write to file, will return an offset

        long offset = 0; // will be file offset

        long seqNum = 0; // will be event.getSeqNum
        this.offsetMap.add((int)(seqNum - this.minSeqNum), offset);
        this.eventCount++;
    }

    public void ensurePersistedUpto(long seqNum) {
        if (this.lastCheckpoint.getEventCount() >= seqNum - this.minSeqNum) {
            checkpoint(lastCheckpoint.getFirstUnackedPageNum());
        }
    }


    public BeheadedPage behead() {
        // TODO:
        // closes this page
        // creates a new BeheadedPage, passing its own structure
        // calls BeheadedPage.checkpoint
        // return this new BeheadedPage

        return null;
    }

    public void checkpoint(int firstUnackedPageNum) {
        // not concurrent for first iteration:

        // TODO:
        // fsync();
        // Checkpoint.write("checkpoint.head", ... )
    }

}
