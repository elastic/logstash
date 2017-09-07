package org.logstash.plugin;

import org.logstash.Event;

import java.util.*;

class BatchImpl implements ProcessorBatch {
    private Collection<Event> events;
    private Map<Event, FailureContext> failures = new TreeMap<>();

    BatchImpl(Collection<Event> events) {
        this.events = events;
    }

    @Override
    public void remove(Event event) throws NoSuchElementException {
        events.remove(event);
    }

    @Override
    public void add(Event event) {
        events.add(event);
    }

    @Override
    public void fail(Event entry, FailureContext context) {
        failures.put(entry, context);
    }

    @Override
    public int size() {
        return events.size();
    }

    @Override
    public Iterator iterator() {
        return events.iterator();
    }

    Map<Event, FailureContext> failures() {
        return failures;
    }
}
