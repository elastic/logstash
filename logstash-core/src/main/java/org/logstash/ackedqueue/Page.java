package org.logstash.ackedqueue;

import java.io.Closeable;
import java.io.IOException;
import java.util.ArrayList;
import java.util.BitSet;
import java.util.List;
import org.logstash.ackedqueue.io.LongVector;
import org.logstash.ackedqueue.io.PageIO;

public abstract class Page implements Closeable {
    protected final int pageNum;
    protected long minSeqNum; // TODO: see if we can make it final?
    protected int elementCount;
    protected long firstUnreadSeqNum;
    protected final Queue queue;
    protected PageIO pageIO;

    // bit 0 is minSeqNum
    // TODO: go steal LocalCheckpointService in feature/seq_no from ES
    // TODO: https://github.com/elastic/elasticsearch/blob/feature/seq_no/core/src/main/java/org/elasticsearch/index/seqno/LocalCheckpointService.java
    protected BitSet ackedSeqNums;
    protected Checkpoint lastCheckpoint;

    public Page(int pageNum, Queue queue, long minSeqNum, int elementCount, long firstUnreadSeqNum, BitSet ackedSeqNums, PageIO pageIO) {
        this.pageNum = pageNum;
        this.queue = queue;

        this.minSeqNum = minSeqNum;
        this.elementCount = elementCount;
        this.firstUnreadSeqNum = firstUnreadSeqNum;
        this.ackedSeqNums = ackedSeqNums;
        this.lastCheckpoint = new Checkpoint(0, 0, 0, 0, 0);
        this.pageIO = pageIO;
    }

    public String toString() {
        return "pageNum=" + this.pageNum + ", minSeqNum=" + this.minSeqNum + ", elementCount=" + this.elementCount + ", firstUnreadSeqNum=" + this.firstUnreadSeqNum;
    }

    /**
     * @param limit the maximum number of elements to read
     * @return {@link SequencedList}<byte[]> collection of elements read. the number of elements can be <= limit
     */
    public SequencedList<byte[]> read(int limit) throws IOException {

        // first make sure this page is activated, activating previously activated is harmless
        this.pageIO.activate();

        SequencedList<byte[]> serialized = this.pageIO.read(this.firstUnreadSeqNum, limit);
        assert serialized.getSeqNums().get(0) == this.firstUnreadSeqNum :
            String.format("firstUnreadSeqNum=%d != first result seqNum=%d", this.firstUnreadSeqNum, serialized.getSeqNums().get(0));

        this.firstUnreadSeqNum += serialized.getElements().size();

        return serialized;
    }

    /**
     * Page is considered empty if it does not contain any element or if all elements are acked.
     *
     * TODO: note that this should be the same as isFullyAcked once fixed per https://github.com/elastic/logstash/issues/7570
     *
     * @return true if the page has no element or if all elements are acked.
     */
    public boolean isEmpty() {
        return this.elementCount == 0 || isFullyAcked();
    }

    public boolean isFullyRead() {
        return unreadCount() <= 0;
//        return this.elementCount <= 0 || this.firstUnreadSeqNum > maxSeqNum();
    }

    public boolean isFullyAcked() {
        // TODO: it should be something similar to this when we use a proper bitset class like ES
        // this.ackedSeqNum.firstUnackedBit >= this.elementCount;
        // TODO: for now use a naive & inefficient mechanism with a simple Bitset
        return this.elementCount > 0 && this.ackedSeqNums.cardinality() >= this.elementCount;
    }

    public long unreadCount() {
        return this.elementCount <= 0 ? 0 : Math.max(0, (maxSeqNum() - this.firstUnreadSeqNum) + 1);
    }

    // update the page acking bitset. trigger checkpoint on the page if it is fully acked or if we acked more than the
    // configured threshold checkpointMaxAcks.
    // note that if the fully acked tail page is the first unacked page, it is not really necessary to also checkpoint
    // the head page to update firstUnackedPageNum because it will be updated in the next upcoming head page checkpoint
    // and in a crash condition, the Queue open recovery will detect and purge fully acked pages
    //
    // @param seqNums the list of same-page seqNums to ack
    // @param checkpointMaxAcks the number of acks that will trigger a page checkpoint
    public void ack(LongVector seqNums, int checkpointMaxAcks) throws IOException {
        final int count = seqNums.size();
        for (int i = 0; i < count; ++i) {
            final long seqNum = seqNums.get(i);
            // TODO: eventually refactor to use new bit handling class

            assert seqNum >= this.minSeqNum :
                    String.format("seqNum=%d is smaller than minSeqnum=%d", seqNum, this.minSeqNum);

            assert seqNum < this.minSeqNum + this.elementCount:
                    String.format("seqNum=%d is greater than minSeqnum=%d + elementCount=%d = %d", seqNum, this.minSeqNum, this.elementCount, this.minSeqNum + this.elementCount);
            int index = (int)(seqNum - this.minSeqNum);

            this.ackedSeqNums.set(index);
        }

        // checkpoint if totally acked or we acked more than checkpointMaxAcks elements in this page since last checkpoint
        // note that fully acked pages cleanup is done at queue level in Queue.ack()
        long firstUnackedSeqNum = firstUnackedSeqNum();

        if (isFullyAcked()) {
            checkpoint();

            assert firstUnackedSeqNum >= this.minSeqNum + this.elementCount - 1:
                    String.format("invalid firstUnackedSeqNum=%d for minSeqNum=%d and elementCount=%d and cardinality=%d", firstUnackedSeqNum, this.minSeqNum, this.elementCount, this.ackedSeqNums.cardinality());

        } else if (checkpointMaxAcks > 0 && (firstUnackedSeqNum >= this.lastCheckpoint.getFirstUnackedSeqNum() + checkpointMaxAcks)) {
            // did we acked more than checkpointMaxAcks elements? if so checkpoint now
            checkpoint();
        }
    }

    public abstract void checkpoint() throws IOException;

    public abstract void close() throws IOException;

    public int getPageNum() {
        return pageNum;
    }

    public long getMinSeqNum() {
        return this.minSeqNum;
    }

    public int getElementCount() {
        return elementCount;
    }

    public PageIO getPageIO() {
        return pageIO;
    }

    protected long maxSeqNum() {
        return this.minSeqNum + this.elementCount - 1;
    }

    protected long firstUnackedSeqNum() {
        // TODO: eventually refactor to use new bithandling class
        return this.ackedSeqNums.nextClearBit(0) + this.minSeqNum;
    }

}
