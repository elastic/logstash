package org.logstash.ackedqueue;

import org.logstash.common.io.PageIO;

import java.io.IOException;
import java.util.BitSet;

public class BeheadedPage extends Page {

    // create a new BeheadedPage object from a HeadPage object
    public BeheadedPage(HeadPage page) {
        super(page.pageNum, page.queue, page.minSeqNum, page.elementCount, page.firstUnreadSeqNum, page.ackedSeqNums, page.pageIO, page.checkpointIO);
    }

    public BeheadedPage(Checkpoint checkpoint, Queue queue, PageIO pageIO) throws IOException {
        super(checkpoint.getPageNum(), queue, checkpoint.getMinSeqNum(), checkpoint.getElementCount(), checkpoint.getFirstUnackedSeqNum(), new BitSet(), pageIO, queue.getCheckpointIO());
        pageIO.open(checkpoint.getMinSeqNum(), checkpoint.getElementCount());

        // if we have some acked elements, set them in the bitset
        if (checkpoint.getFirstUnackedSeqNum() > checkpoint.getMinSeqNum()) {
            this.ackedSeqNums.flip(0, (int) (checkpoint.getFirstUnackedSeqNum() - checkpoint.getMinSeqNum()));
        }
    }

    public void checkpoint() throws IOException {
        // not concurrent for first iteration:

        // TODO:
        // fsync();
        this.checkpointIO.write("checkpoint." + pageNum, this.pageNum, firstUnackedPageNumFromQueue(), firstUnackedSeqNum(), this.minSeqNum, this.elementCount);
    }

    void checkpoint(int firstUnackedPageNum) {
        // TODO:
        // Checkpoint.write("checkpoint." + this.pageNum, ... );
    }

}