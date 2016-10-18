package org.logstash.ackedqueue;

import org.logstash.common.io.CheckpointIO;
import org.logstash.common.io.PageIO;

import java.io.IOException;
import java.util.BitSet;

public class HeadPage extends Page {

    // create a new HeadPage object and new page.{pageNum} empty valid data file
    public HeadPage(int pageNum, Queue queue, PageIO pageIO) throws IOException {
        super(pageNum, queue, 0, 0, 0, new BitSet(), pageIO);
        pageIO.create();
    }

    // verify if data size plus overhead is not greater than the page capacity
    public boolean hasCapacity(int byteSize) {
        return this.pageIO.persistedByteCount(byteSize) <= this.pageIO.getCapacity();
    }

    public boolean hasSpace(int byteSize) {
        return this.pageIO.hasSpace((byteSize));
    }

    // NOTE:
    // we have a page concern inconsistency where readBatch() takes care of the
    // deserialization and returns a Batch object which contains the deserialized
    // elements objects of the proper elementClass but HeadPage.write() deals with
    // a serialized element byte[] and serialization is done at the Queue level to
    // be able to use the Page.hasSpace() method with the serialized element byte size.
    //
    public void write(byte[] bytes, long seqNum) throws IOException {
        this.pageIO.write(bytes, seqNum);

        if (this.minSeqNum <= 0) {
            this.minSeqNum = seqNum;
            this.firstUnreadSeqNum = seqNum;
        }
        this.elementCount++;
    }

    public void ensurePersistedUpto(long seqNum) throws IOException {
        long lastCheckpointUptoSeqNum = this.lastCheckpoint.getMinSeqNum() + this.lastCheckpoint.getElementCount();

        // if the last checkpoint for this headpage already included the given seqNum, no need to fsync/checkpoint
        if (seqNum > lastCheckpointUptoSeqNum) {
            // head page checkpoint does a data file fsync
            checkpoint();
        }
    }


    public BeheadedPage behead() throws IOException {
        // first do we need to checkpoint+fsync the headpage a last time?
        if (this.elementCount > this.lastCheckpoint.getElementCount()) {
            checkpoint();
        }

        BeheadedPage beheadedPage = new BeheadedPage(this);

        // first thing that must be done after beheading is to create a new checkpoint for that new tail page
        // tail page checkpoint does NOT includes a fsync
        beheadedPage.checkpoint();

        // TODO: should we have a better deactivation strategy to avoid too rapid reactivation scenario?
        Page firstUnreadPage = queue.firstUnreadPage();
        if (firstUnreadPage == null || (beheadedPage.getPageNum() > firstUnreadPage.getPageNum())) {
            // deactivate if this new beheadedPage is not where the read is occuring
            beheadedPage.getPageIO().deactivate();
        }

        return beheadedPage;
    }

    public void checkpoint() throws IOException {
        // TODO: not concurrent for first iteration:

        // first fsync data file
        this.pageIO.ensurePersisted();

        // then write new checkpoint

        CheckpointIO io = queue.getCheckpointIO();
        this.lastCheckpoint = io.write(io.headFileName(), this.pageNum, this.queue.firstUnackedPageNum(), firstUnackedSeqNum(), this.minSeqNum, this.elementCount);
     }

    public void close() throws IOException {
        checkpoint();
        this.pageIO.close();
    }

}
