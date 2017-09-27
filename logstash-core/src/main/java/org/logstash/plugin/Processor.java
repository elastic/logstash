package org.logstash.plugin;

import org.logstash.Event;

import java.util.Collection;

public interface Processor {
    /**
     * Process events. In the past, this was called a `filter` in Logstash.
     *
     * @param events The events to be processed
     * @return Any new events created by this processor.
     */
    void process(Collection<Event> events);
}
