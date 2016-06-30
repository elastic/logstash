package org.logstash.ackedqueue;

import java.util.ArrayList;
import java.util.BitSet;
import java.util.List;

public abstract class Page {
    protected final int pageNum;
    protected final List<Long> offsetMap; // has to be extendable
    protected final long minSeqNum;
    protected int eventCount;
    protected long firstUnreadSeqNum;

    // bit 0 is minSeqNum
    // TODO: go steal LocalCheckpointService in feature/seq_no from ES
    // TODO: https://github.com/elastic/elasticsearch/blob/feature/seq_no/core/src/main/java/org/elasticsearch/index/seqno/LocalCheckpointService.java
    private final BitSet ackedSeqNums;

    protected Checkpoint lastCheckpoint;

    public Page() {
        // TODO: contructor
        this.pageNum = 0;
        this.offsetMap = new ArrayList<>();
        this.minSeqNum = 0;
        this.ackedSeqNums = new BitSet();
    }

    // @param limit the batch size limit
    // @return Batch batch of events read when the number of events can be <= limit
    Batch readBatch(int limit) {
        // TODO:
        // read upto limit events for this page
        // starting at firstUnreadSeqNum offset
        // fill batch

        // update readPage firstUnreadSeqNum

        // return batch

        return null;
    }

    boolean isFullyRead() {
        return this.firstUnreadSeqNum != maxSeqNum();
    }

    boolean isFullyAcked() {

        // TODO: it should be something similar to this when we use a proper bitset class like ES
        // this.ackedSeqNum.firstUnackedBit >= this.eventCount;

        // TODO: for now use a naive & inneficient mechanism with a simple Bitset
        return this.ackedSeqNums.cardinality() >= this.eventCount;
    }

    void ack(long[] seqNums) {

        for(long seqNum : seqNums) {
            // TODO: eventually refactor to use new bit handling class
            this.ackedSeqNums.set((int)(seqNum - this.minSeqNum));
        }

        // TODO: verify logic below

//        if (firstUnackedSeqNum() > this.lastCheckpoint.firstUnackedPageNum + 1024) {
//            checkpoint(this.lastCheckpoint.firstUnackedPageNum);
//
//        }
    }

    abstract void checkpoint(int firstUnackedPageNum);


    long maxSeqNum() {
        return this.minSeqNum + this.eventCount;
    }

    public int getPageNum() {
        return pageNum;
    }

    private long firstUnackedSeqNum() {
        // TODO: eventually refactor to use new bithandling class


        // TODO: find first unacked bit in ackedSeqNum
        int bitPos = 0;

        return bitPos + this.minSeqNum;
    }
}
