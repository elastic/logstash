package org.logstash.ackedqueue;


import org.roaringbitmap.RoaringBitmap;

import java.io.IOException;
import java.util.SortedMap;
import java.util.TreeMap;

// TODO: add iterators for pages with unused/unacked bits? this would need to tie-in with the pagehandler
// TODO: page method strategy, or simply just provide a simple page number interator

public class VolatileQueueState implements QueueState {
    // head tracking for writes
    private int headPageIndex;
    private int headPageOffset;

    // tail tracking, offset tracking is not necessary since it uses the per-page bitsets
    private int unackedTailPageIndex; // tail page with the oldest unacked bits
    private int unusedTailPageIndex;  // tail page with the oldest unused bits

    // in use page byte size
    private int pageSize;

    private SortedMap<Long, Page> activePageStates; // active pages PageState
    private RoaringBitmap validPages; // all non fully acked pages


    // @param pageSize the queue page pageSize
    public VolatileQueueState(int pageSize) {
        this.pageSize = pageSize;
        this.headPageIndex = 0;
        this.headPageOffset = 0;
        this.unackedTailPageIndex = 0;
        this.unusedTailPageIndex = 0;

        this.activePageStates = new TreeMap<>();
        this.validPages = new RoaringBitmap();
    }

    @Override
    public int getHeadPageIndex() {
        return headPageIndex;
    }

    @Override
    public void setHeadPageIndex(int index) {
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
    public int getUnackedTailPageIndex() {
        return unackedTailPageIndex;
    }

    @Override
    public void setUnackedTailPageIndex(int index) {
        this.unackedTailPageIndex = index;
    }

    @Override
    public int getUnusedTailPageIndex() {
        return unusedTailPageIndex;
    }

    @Override
    public void setUnusedTailPageIndex(int index) {
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

    public void addValidPage(int index) {
        validPages.add(index);
    }

    public void removeValidPage(int index) {

    }


    @Override
    public void close() throws IOException {
        // TBD
    }
}
