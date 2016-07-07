package org.logstash.common.io;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class MemoryCheckpointIO2 implements CheckpointIO {
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
    private static final Map<String, MemoryCheckpointIO2> sources = new HashMap<>();

    public static final byte VERSION = 0;

    public MemoryCheckpointIO2(String source) {
        this.source = source;
    }

    @Override
    public void read() throws IOException {
        MemoryCheckpointIO2 checkpoint = sources.get(this.source);
        if (checkpoint == null) {
            throw new FileNotFoundException("checkpoint " + source + " does not exist");
        }

        this.pageNum = checkpoint.getPageNum();
        this.firstUnackedPageNum =checkpoint.getFirstUnackedPageNum();
        this.firstUnackedSeqNum = checkpoint.getFirstUnackedSeqNum();
        this.minSeqNum = checkpoint.getMinSeqNum();
        this.elementCount = checkpoint.getElementCount();
    }

    @Override
    public void write(int pageNum, int firstUnackedPageNum, long firstUnackedSeqNum, long minSeqNum, int elementCount) throws IOException {
        MemoryCheckpointIO2 checkpoint = new MemoryCheckpointIO2(this.source);
        checkpoint.pageNum = pageNum;
        checkpoint.firstUnackedPageNum = firstUnackedPageNum;
        checkpoint.firstUnackedSeqNum = firstUnackedSeqNum;
        checkpoint.minSeqNum = minSeqNum;
        checkpoint.elementCount = elementCount;
        this.sources.put(this.source, checkpoint);
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
