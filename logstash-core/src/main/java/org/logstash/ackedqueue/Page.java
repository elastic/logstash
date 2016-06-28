package org.logstash.ackedqueue;

public abstract class Page {

    // @param limit the batch size limit
    // @return Batch batch of events read when the number of events can be <= limit
    Batch readBatch(int limit) {
        // TBD
        return null;
    }

    boolean isFullyRead() {
        // TBD
        return true;
    }

    boolean isFullyAcked() {
        // TBD
        return true;
    }

    void ack(long[] seqNums) {
        // TBD
    }

    void checkpoint(int firstUnackedPageNum) {
        // TBD
    }

}
