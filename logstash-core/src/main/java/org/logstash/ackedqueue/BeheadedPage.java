package org.logstash.ackedqueue;

import org.logstash.common.io.PageIO;

import java.io.IOException;
import java.util.BitSet;

public class BeheadedPage extends Page {

    // create a new BeheadedPage object from a HeadPage object
    public BeheadedPage(HeadPage page) {
        super(page.pageNum, page.queue, page.minSeqNum, page.elementCount, page.firstUnreadSeqNum, page.ackedSeqNums, page.pageIO);
    }

    // create a new BeheadedPage object for an exiting Checkpoint and data file
    public BeheadedPage(Checkpoint checkpoint, Queue queue, PageIO pageIO) throws IOException {
        super(checkpoint.getPageNum(), queue, checkpoint.getMinSeqNum(), checkpoint.getElementCount(), checkpoint.getFirstUnackedSeqNum(), new BitSet(), pageIO);

        // open the data file and reconstruct the IO object internal state
        pageIO.open(checkpoint.getMinSeqNum(), checkpoint.getElementCount());

        // this page ackedSeqNums bitset is a new empty bitset, if we have some acked elements, set them in the bitset
        if (checkpoint.getFirstUnackedSeqNum() > checkpoint.getMinSeqNum()) {
            this.ackedSeqNums.flip(0, (int) (checkpoint.getFirstUnackedSeqNum() - checkpoint.getMinSeqNum()));
        }
    }

    public void checkpoint() throws IOException {
        // TODO: not concurrent for first iteration:

        // since this is a tail page and no write can happen in this page, there is no point in performing a fsync on this page, just stamp checkpoint
        this.lastCheckpoint = queue.getCheckpointIO().write("checkpoint." + this.pageNum, this.pageNum, this.queue.firstUnackedPageNum(), firstUnackedSeqNum(), this.minSeqNum, this.elementCount);
    }

    // delete all IO files associated with this page
    public void purge() throws IOException {
        this.pageIO.purge();
        this.queue.getCheckpointIO().purge("checkpoint." + this.pageNum);
    }

    public void close() throws IOException {
        checkpoint();
        this.pageIO.close();
    }
}