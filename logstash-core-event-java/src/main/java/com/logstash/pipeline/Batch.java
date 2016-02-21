package com.logstash.pipeline;

import com.logstash.Event;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by andrewvc on 2/20/16.
 */
public class Batch {
    private final boolean flush;
    private final boolean shutdown;
    private final List<Event> events;

    Batch(List events, boolean flush, boolean shutdown) {
        this.flush = flush;
        this.shutdown = shutdown;
        this.events = events;
    }

    public List<Event> getEvents() {
        return events;
    }

    public boolean isFlush() {
        return flush;
    }

    public boolean isShutdown() {
        return shutdown;
    }
}
