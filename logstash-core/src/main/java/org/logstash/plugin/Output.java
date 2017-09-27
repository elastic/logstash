package org.logstash.plugin;

import org.logstash.Event;

import java.util.Collection;

public interface Output {
    /**
     * Process a batch with the intent of sending the event externally.
     *
     * @param events the events to output.
     */
    void process(Collection<Event> events);
}
