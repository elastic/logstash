package org.logstash.ackedqueue;

import org.logstash.common.io.ElementIO;

import java.io.IOException;
import java.util.BitSet;

public class BeheadedPage extends Page {


    // create a new BeheadedPage object from a HeadPage object
    public BeheadedPage(HeadPage page) {
        super(page.pageNum, page.queue, page.minSeqNum, page.elementCount, page.firstUnreadSeqNum, (BitSet) page.ackedSeqNums.clone(), page.io);
    }

    public BeheadedPage(Checkpoint checkpoint, Queue queue) throws IOException {
        super(checkpoint.getPageNum(), queue, checkpoint.getMinSeqNum(), checkpoint.getElementCount(), checkpoint.getFirstUnackedSeqNum(), null, null);
        this.io = queue.getIo().open(queue.getIo().getCapacity(), "", checkpoint.getMinSeqNum(), checkpoint.getElementCount());

        BitSet bs = new BitSet();

        // if we have some acked elements, set them in the bitset
        if (checkpoint.getFirstUnackedSeqNum() > checkpoint.getMinSeqNum()) {
            bs.flip(0, (int) (checkpoint.getFirstUnackedSeqNum() - checkpoint.getMinSeqNum()));
        }
        this.ackedSeqNums = bs;
    }

    void checkpoint(long firstUnackedSeqNum) {
        // TODO:
        // Checkpoint.write("checkpoint." + this.pageNum, ... );
    }

}