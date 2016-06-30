package org.logstash.ackedqueue;

public class BeheadedPage extends Page {


    public BeheadedPage(Checkpoint cp) {
        // TODO:
    }


    public BeheadedPage(HeadPage p) {
        // TODO:
    }

    void checkpoint(int firstUnackedPageNum) {
        // TODO:
        // Checkpoint.write("checkpoint." + this.pageNum, ... );
    }

}