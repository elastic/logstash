package org.logstash.previous_ackedqueue;

import java.util.HashMap;
import java.util.Map;

public class VolatilePagedQueue extends PagedQueue {
    private Map<Integer, Page> pages;

    public VolatilePagedQueue(int pageSize) {
        super(new VolatileQueueState(pageSize));

        this.pages = new HashMap<>();

        // warm head and tail pages and set initial active pages
        // this is obviously not very useful in a volatile implementation but it illustrate the logic
        page(this.queueState.getHeadPageIndex());
        if (this.queueState.getHeadPageIndex() != this.queueState.getUnackedTailPageIndex()) {
            page(this.queueState.getUnackedTailPageIndex());
        }

    }

    // pages opening/caching strategy
    // @param index the page index to retrieve
    protected Page page(int index) {
        Page p = this.pages.get(index);
        if (p != null) {
            return p;
        }

        p = new MemoryPage(this.queueState.getPageSize(), index);
        this.pages.put(index, p);
        return p;
    }
}
