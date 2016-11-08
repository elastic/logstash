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

    // @return true if this checkpoint indicates a fulle acked page
    public boolean isFullyAcked() {
        return this.elementCount > 0 && this.firstUnackedSeqNum >= this.minSeqNum + this.elementCount;
    }

    // @return the highest seqNum in this page or -1 for an initial checkpoint
    public long maxSeqNum() {
        return this.minSeqNum + this.elementCount - 1;
    }

    public String toString() {
        return "pageNum=" + this.pageNum + ", firstUnackedPageNum=" + this.firstUnackedPageNum + ", firstUnackedSeqNum=" + this.firstUnackedSeqNum + ", minSeqNum=" + this.minSeqNum + ", elementCount=" + this.elementCount + ", isFullyAcked=" + (this.isFullyAcked() ? "yes" : "no");
    }

    public boolean equals(Checkpoint other) {
        if (this == other ) { return true; }
        return (this.pageNum == other.pageNum && this.firstUnackedPageNum == other.firstUnackedPageNum && this.firstUnackedSeqNum == other.firstUnackedSeqNum && this.minSeqNum == other.minSeqNum && this.elementCount == other.elementCount);
    }

}
