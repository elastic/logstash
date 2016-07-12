package org.logstash.ackedqueue;

public class Checkpoint {
//    Checkpoint file structure see FileCheckpointIO

    public static final int VERSION = 1;

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
