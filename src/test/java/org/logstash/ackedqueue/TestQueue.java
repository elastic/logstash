package org.logstash.ackedqueue;

import java.util.List;

public class TestQueue extends Queue {
    public TestQueue(Settings settings) {
        super(settings);
    }

    public HeadPage getHeadPage() {
        return this.headPage;
    }

    public List<TailPage> getTailPages() {
        return this.tailPages;
    }
}
