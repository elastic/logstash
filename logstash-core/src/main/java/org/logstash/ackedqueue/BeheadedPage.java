package org.logstash.ackedqueue;

public class BeheadedPage extends Page {


    public BeheadedPage(Checkpoint cp, Queue queue) {
        super(0, queue);
        // TODO:
    }


    public BeheadedPage(HeadPage p, Queue queue) {
        super(0, queue);
        // TODO:
    }

    void checkpoint(long firstUnackedSeqNum) {
        // TODO:
        // Checkpoint.write("checkpoint." + this.pageNum, ... );
    }

}