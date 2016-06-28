package org.logstash.ackedqueue;

public class Checkpoint {
    private int pageNum;
    private int firstUnackedPageNum; // only valid in the head checkpoint
    long minSeqNum;     // per page
    int eventCount;     // per page
    int fullyAckedUpto; // per page

    public Checkpoint() {
        // TBD
    }

    static void write(String filename) {
        // TBD
    }

    static Checkpoint read(String filename) {
        // TBD

        return null;
    }
}
