package org.logstash.ackedqueue;

import java.util.HashMap;
import java.util.Map;

public class VolatilePagedQueue extends PagedQueue {
    private Map<Long, Page> livePages;

    public VolatilePagedQueue(int pageSize) {
        super(pageSize);

        this.queueState = new VolatileQueueState();
        this.queueState.setPageSize(this.pageSize);
        this.queueState.setHeadPageIndex(0);
        this.queueState.setHeadPageOffset(0);
        this.queueState.setUnackedTailPageIndex(0);
        this.queueState.setUnusedTailPageIndex(0);

        this.livePages = new HashMap<>();
    }

    // pages opening/caching strategy
    // @param index the page index to retrieve
    protected Page page(long index) {
        // TODO: adjust implementation for correct live pages handling
        // TODO: extract page caching in a separate class?

        Page p = this.livePages.get(index);
        if (p != null) {
            return p;
        }

        p = new MemoryPage(this.pageSize, index);
        this.livePages.put(index, p);
        return p;
    }
}
