package org.logstash.ackedqueue;

import org.logstash.common.io.CheckpointIO;
import org.logstash.common.io.PageIO;

import java.io.IOException;
import java.util.BitSet;

public class TailPage extends Page {

    // create a new TailPage object from a HeadPage object
    public TailPage(HeadPage page) {
        super(page.pageNum, page.queue, page.minSeqNum, page.elementCount, page.firstUnreadSeqNum, page.ackedSeqNums, page.pageIO);
    }

    // create a new TailPage object for an exiting Checkpoint and data file
    public TailPage(Checkpoint checkpoint, Queue queue, PageIO pageIO) throws IOException {
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
        CheckpointIO io = queue.getCheckpointIO();
        this.lastCheckpoint = io.write(io.tailFileName(this.pageNum), this.pageNum, this.queue.firstUnackedPageNum(), firstUnackedSeqNum(), this.minSeqNum, this.elementCount);
    }

    // delete all IO files associated with this page
    public void purge() throws IOException {
        this.pageIO.purge();
        CheckpointIO io = queue.getCheckpointIO();
        io.purge(io.tailFileName(this.pageNum));
    }

    public void close() throws IOException {
        checkpoint();
        this.pageIO.close();
    }
}