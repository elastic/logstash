package org.logstash.ackedqueue;

import org.logstash.common.io.ElementIO;
import org.logstash.common.io.ReadElementValue;

import java.io.IOException;
import java.util.BitSet;
import java.util.List;
import java.util.stream.Collectors;

public abstract class Page {
    protected final int pageNum;
    protected long minSeqNum; // TODO: see if we can meke it final?
    protected int elementCount;
    protected long firstUnreadSeqNum;
    protected final Queue queue;
    protected ElementIO io;

    protected Settings settings;

    // bit 0 is minSeqNum
    // TODO: go steal LocalCheckpointService in feature/seq_no from ES
    // TODO: https://github.com/elastic/elasticsearch/blob/feature/seq_no/core/src/main/java/org/elasticsearch/index/seqno/LocalCheckpointService.java
    protected BitSet ackedSeqNums;
    protected Checkpoint lastCheckpoint;

    public Page(int pageNum, Queue queue, long minSeqNum, int elementCount, long firstUnreadSeqNum, BitSet ackedSeqNums, ElementIO io) {
        this.pageNum = pageNum;
        this.queue = queue;

        this.minSeqNum = minSeqNum;
        this.elementCount = elementCount;
        this.firstUnreadSeqNum = firstUnreadSeqNum;
        this.ackedSeqNums = ackedSeqNums;
        this.lastCheckpoint = null;
        this.io = io;
    }

    public Page(int pageNum, Queue queue) {
        this(pageNum, queue, 0, 0, 0, new BitSet(), null);
    }

    public Page(int pageNum, Queue queue, Settings settings) {
        this(pageNum, queue, settings, 0, 0, 0, new BitSet(), null);
    }

    public Page(int pageNum, Queue queue, Settings settings, long minSeqNum, int elementCount, long firstUnreadSeqNum, BitSet ackedSeqNums, ElementIO io) {
        this.pageNum = pageNum;
        this.queue = queue;
        this.settings = settings;
        this.minSeqNum = minSeqNum;
        this.elementCount = elementCount;
        this.firstUnreadSeqNum = firstUnreadSeqNum;
        this.ackedSeqNums = ackedSeqNums;
        this.lastCheckpoint = null;
        this.io = io;
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
    public Batch readBatch(int limit) {
        List<ReadElementValue> serializedElements = this.io.read(this.firstUnreadSeqNum, limit);
        List<Queueable> elements = serializedElements.stream().map(readElement -> ElementFactory.deserialize(readElement.getBinaryValue())).collect(Collectors.toList());
        Batch batch = new Batch(elements, this.queue);

        this.firstUnreadSeqNum += elements.size();

        return batch;
    }

    public boolean isFullyRead() {
        return this.elementCount <= 0 || this.firstUnreadSeqNum > maxSeqNum();
    }

    public boolean isFullyAcked() {
        // TODO: it should be something similar to this when we use a proper bitset class like ES
        // this.ackedSeqNum.firstUnackedBit >= this.elementCount;
        // TODO: for now use a naive & inneficient mechanism with a simple Bitset
        return this.elementCount > 0 && this.ackedSeqNums.cardinality() >= this.elementCount;
    }

    public void ack(long[] seqNums) throws IOException {
        for (long seqNum : seqNums) {
            // TODO: eventually refactor to use new bit handling class
            this.ackedSeqNums.set((int)(seqNum - this.minSeqNum));
        }

        // checkpoint if totally acked or we acked more than 1024 elements in this page since last checkpoint
        long firstUnackedSeqNum = firstUnackedSeqNum();

        if (isFullyAcked()) {
            checkpoint();

            assert firstUnackedSeqNum >= this.minSeqNum + this.elementCount :
                    String.format("invalid firstUnackedSeqNum=%d for minSeqNum=%d and elementCount=%d", firstUnackedSeqNum, this.minSeqNum, this.elementCount);
        } else if (firstUnackedSeqNum > this.lastCheckpoint.getFirstUnackedSeqNum() + 1024) {
            checkpoint();
        }
    }

    abstract void checkpoint() throws IOException;

    public int getPageNum() {
        return pageNum;
    }

    public long getMinSeqNum() {
        return this.minSeqNum;
    }

    public Queue getQueue() {
        return queue;
    }

    protected long maxSeqNum() {
        return this.minSeqNum + this.elementCount - 1;
    }

    protected long firstUnackedSeqNum() {
        // TODO: eventually refactor to use new bithandling class
        return this.ackedSeqNums.nextClearBit(0) + this.minSeqNum;
    }

    protected int firstUnackedPageNumFromQueue() {
        return queue.firstUnackedPageNum();
    }
}
