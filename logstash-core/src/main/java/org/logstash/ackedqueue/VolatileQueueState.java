package org.logstash.ackedqueue;


import java.io.IOException;

// TODO: add iterators for pages with unused/unacked bits? this would need to tie-in with the pagehandler
// TODO: page method strategy, or simply just provide a simple page number interator

public class VolatileQueueState implements QueueState {
    // head tracking for writes
    private long headPageIndex;
    private int headPageOffset;

    // tail tracking, offset tracking is not necessary since it uses the per-page bitsets
    private long unackedTailPageIndex; // tail page with the oldest unacked bits
    private long unusedTailPageIndex;  // tail page with the oldest unused bits

    // in use page byte size
    private int pageSize;

    public VolatileQueueState() {
        // TBD
    }

    @Override
    public long getHeadPageIndex() {
        return headPageIndex;
    }

    @Override
    public void setHeadPageIndex(long index) {
        this.headPageIndex = index;
    }

    @Override
    public int getHeadPageOffset() {
        return headPageOffset;
    }

    @Override
    public void setHeadPageOffset(int offset) {
        this.headPageOffset = offset;
    }

    @Override
    public long getUnackedTailPageIndex() {
        return unackedTailPageIndex;
    }

    @Override
    public void setUnackedTailPageIndex(long index) {
        this.unackedTailPageIndex = index;
    }

    @Override
    public long getUnusedTailPageIndex() {
        return unusedTailPageIndex;
    }

    @Override
    public void setUnusedTailPageIndex(long index) {
        this.unusedTailPageIndex = index;
    }

    @Override
    public int getPageSize() {
        return pageSize;
    }

    @Override
    public void setPageSize(int size) {
        this.pageSize = size;
    }

    @Override
    public void close() throws IOException {
        // TBD
    }
}
