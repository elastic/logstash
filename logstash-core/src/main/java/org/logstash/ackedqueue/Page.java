package org.logstash.ackedqueue;

import org.logstash.common.io.ReadElementValue;

import java.util.ArrayList;
import java.util.BitSet;
import java.util.List;
import java.util.stream.Collectors;

public abstract class Page {
    protected final int pageNum;
    protected final List<Long> offsetMap; // has to be extendable
    protected final long minSeqNum;
    protected int elementCount;
    protected long firstUnreadSeqNum;
    protected final Queue queue;

    // bit 0 is minSeqNum
    // TODO: go steal LocalCheckpointService in feature/seq_no from ES
    // TODO: https://github.com/elastic/elasticsearch/blob/feature/seq_no/core/src/main/java/org/elasticsearch/index/seqno/LocalCheckpointService.java
    private final BitSet ackedSeqNums;

    protected Checkpoint lastCheckpoint;

    public Page(int pageNum, Queue queue) {
        this.pageNum = pageNum;
        this.queue = queue;

        this.offsetMap = new ArrayList<>();
        this.minSeqNum = 0;
        this.elementCount = 0;
        this.firstUnreadSeqNum = 0;
        this.ackedSeqNums = new BitSet();
        this.lastCheckpoint = null;
    }

    // NOTE:
    // we have a page concern inconsistency where readBatch() takes care of the
    // deserialization and returns a Batch object which contains the deserialized
    // elements objects of the proper elementClass but HeadPage.write() deals with
    // a serialized element byte[] and serialization is done at the Queue level to
    // be able to use the Page.hasSpace() method with the serialized element byte size.
    //
    // @param limit the batch size limit
    // @param elementClass the concrete element class for deserialization
    // @return Batch batch of elements read when the number of elements can be <= limit
    Batch readBatch(int limit) {
        List<ReadElementValue> serializedElements = this.queue.getStream().read(this.offsetMap.get((int)(this.firstUnreadSeqNum - this.minSeqNum)), limit);
        List<Queueable> elements = serializedElements.stream().map(readElement -> ElementFactory.deserialize(readElement.getBinaryValue())).collect(Collectors.toList());
        Batch batch = new Batch(elements, this.queue);

        this.firstUnreadSeqNum += elements.size();

        return batch;
    }

    boolean isFullyRead() {
        return this.firstUnreadSeqNum > maxSeqNum();
    }

    boolean isFullyAcked() {

        // TODO: it should be something similar to this when we use a proper bitset class like ES
        // this.ackedSeqNum.firstUnackedBit >= this.elementCount;

        // TODO: for now use a naive & inneficient mechanism with a simple Bitset
        return this.ackedSeqNums.cardinality() >= this.elementCount;
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
        return this.minSeqNum + this.elementCount;
    }

    public int getPageNum() {
        return pageNum;
    }

    public Queue getQueue() {
        return queue;
    }

    private long firstUnackedSeqNum() {
        // TODO: eventually refactor to use new bithandling class


        // TODO: find first unacked bit in ackedSeqNum
        int bitPos = 0;

        return bitPos + this.minSeqNum;
    }
}
