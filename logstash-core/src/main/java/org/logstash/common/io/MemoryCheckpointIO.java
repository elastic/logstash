package org.logstash.common.io;

import java.io.IOException;

public class MemoryCheckpointIO implements CheckpointIO {
//    Checkpoint file structure
//
//    byte version;
//    int pageNum;
//    int firstUnackedPageNum;
//    long firstUnackedSeqNum;
//    long minSeqNum;
//    int elementCount;

    private int pageNum;       // local per-page page number
    private long minSeqNum;    // local per-page minimum seqNum
    private int elementCount;        // local per-page element count
    private long firstUnackedSeqNum; // local per-page unacknowledged tracking
    private int firstUnackedPageNum; // queue-wide global pointer, only valid in the head checkpoint

    private final String source;

    public static final byte VERSION = 0;

    public MemoryCheckpointIO(String source) {
        this.source = source;
    }

    @Override
    public void read() throws IOException {
        String[] parts = source.split("|");
        this.pageNum = Integer.valueOf(parts[0]);
        this.firstUnackedPageNum = Integer.valueOf(parts[2]);
        this.firstUnackedSeqNum = Long.valueOf(parts[3]);
        this.minSeqNum = Long.valueOf(parts[4]);
        this.elementCount = Integer.valueOf(parts[5]);
    }

    @Override
    public void write(int firstUnackedPageNum, long firstUnackedSeqNum, int elementCount)  throws IOException{
        this.firstUnackedPageNum = firstUnackedPageNum;
        this.firstUnackedSeqNum = firstUnackedSeqNum;
        this.elementCount = elementCount;
    }

    public int getPageNum() {
        return this.pageNum;
    }

    public long getMinSeqNum() {
        return this.minSeqNum;
    }

    public long getFirstUnackedSeqNum() {
        return this.firstUnackedSeqNum;
    }

    public int getElementCount() {
        return this.elementCount;
    }

    public int getFirstUnackedPageNum() {
        return this.firstUnackedPageNum;
    }

}
