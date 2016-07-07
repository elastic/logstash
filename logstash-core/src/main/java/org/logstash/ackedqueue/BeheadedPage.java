package org.logstash.ackedqueue;

import java.io.IOException;
import java.util.BitSet;

public class BeheadedPage extends Page {


    // create a new BeheadedPage object from a HeadPage object
    public BeheadedPage(HeadPage page) {
        super(page.pageNum, page.queue, page.minSeqNum, page.elementCount, page.firstUnreadSeqNum, (BitSet) page.ackedSeqNums.clone(), page.elementIO, page.checkpointIO);
    }

    public BeheadedPage(Checkpoint checkpoint, Queue queue, Settings settings) throws IOException {
        super(checkpoint.getPageNum(), queue, checkpoint.getMinSeqNum(), checkpoint.getElementCount(), checkpoint.getFirstUnackedSeqNum(), null, null, queue.getCheckpointIO());
        String fullPagePath = this.settings.getDirPath() + "/page." + pageNum;
        this.elementIO = settings.getElementIOFactory().create(settings.getCapacity(), fullPagePath);

        BitSet bs = new BitSet();

        // if we have some acked elements, set them in the bitset
        if (checkpoint.getFirstUnackedSeqNum() > checkpoint.getMinSeqNum()) {
            bs.flip(0, (int) (checkpoint.getFirstUnackedSeqNum() - checkpoint.getMinSeqNum()));
        }
        this.ackedSeqNums = bs;
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