package org.logstash.ackedqueue;

import org.logstash.common.io.CheckpointIO;

import java.io.IOException;

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
            + Integer.BYTES; // eventCount

    private final CheckpointIO io;

    public static final byte VERSION = 0;

    public static void write(CheckpointIO io, int firstUnackedPageNum, long firstUnackedSeqNum, int elementCount)  throws IOException {
        Checkpoint ckp = new Checkpoint(io);
        ckp.write(firstUnackedPageNum, firstUnackedSeqNum, elementCount);
    }

    public Checkpoint(CheckpointIO io) {
        this.io = io;
    }

    public void read() throws IOException {
        io.read();
    }

    public void write(int firstUnackedPageNum, long firstUnackedSeqNum, int elementCount) throws IOException {
        io.write(firstUnackedPageNum, firstUnackedSeqNum, elementCount);
    }

    public int getPageNum() {
        return io.getPageNum();
    }

    public long getFirstUnackedSeqNum() {
        return io.getFirstUnackedSeqNum();
    }

    public long getMinSeqNum() {
        return io.getMinSeqNum();
    }

    public int getElementCount() {
        return io.getElementCount();
    }

    public int getFirstUnackedPageNum() {
        return io.getFirstUnackedPageNum();
    }

}
