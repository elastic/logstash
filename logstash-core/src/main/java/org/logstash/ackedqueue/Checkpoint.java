package org.logstash.ackedqueue;

public class Checkpoint {
//    Checkpoint file structure as handled by CheckpointIO
//
//    byte version;
//    int pageNum;
//    int firstUnackedPageNum;
//    long firstUnackedSeqNum;
//    long minSeqNum;
//    int elementCount;

    public static final int BUFFER_SIZE = 1 // version
            + Integer.BYTES  // pageNum
            + Integer.BYTES  // firstUnackedPageNum
            + Long.BYTES     // firstUnackedSeqNum
            + Long.BYTES     // minSeqNum
            + Integer.BYTES  // eventCount
            + Long.BYTES;    // checksum

    public static final byte VERSION = 1;

    private final int pageNum;             // local per-page page number
    private final int firstUnackedPageNum; // queue-wide global pointer, only valid in the head checkpoint
    private final long firstUnackedSeqNum; // local per-page unacknowledged tracking
    private final long minSeqNum;          // local per-page minimum seqNum
    private final int elementCount;        // local per-page element count


    public Checkpoint(int pageNum, int firstUnackedPageNum, long firstUnackedSeqNum, long minSeqNum, int elementCount) {
        this.pageNum = pageNum;
        this.firstUnackedPageNum = firstUnackedPageNum;
        this.firstUnackedSeqNum = firstUnackedSeqNum;
        this.minSeqNum = minSeqNum;
        this.elementCount = elementCount;
    }

    public int getPageNum() {
        return this.pageNum;
    }

    public int getFirstUnackedPageNum() {
        return this.firstUnackedPageNum;
    }

    public long getFirstUnackedSeqNum() {
        return this.firstUnackedSeqNum;
    }

    public long getMinSeqNum() {
        return this.minSeqNum;
    }

    public int getElementCount() {
        return this.elementCount;
    }

}
