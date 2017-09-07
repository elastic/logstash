package org.logstash.plugin;

import org.logstash.Event;

import java.util.Collection;

public interface Processor {
    /**
     * 1) By default, events are assumed successful.
     * 2) Cancelling an event will drop it from the batch
     * 3) Failing an event will allow the user to choose what to do on the failure.
     * <p>
     * What kinds of failures can happend?
     * Manufacturing metaphor: Quality Control found an incorrectly-assembled product and pulled it from the
     * production line and put it in a bin for the rework team to attempt to repair later.
     * - Example: incorrect Mapping in ES
     * - Example: Execution timeout (grok got stuck, etc)
     * - Example: json filter (or codec?) failed due to the text being invalid JSON.
     * - Example: date filter failed to match due to date format mismatch
     * - Example: grok filter failed to match any pattern
     * - Example: geoip IP not found
     * - Example: geoip given data is not a valid IP
     * Other failures (temporary transport failures) should be retried indefinitely.
     */
    // drop event, fail event, succeed
    //void process(ProcessorBatch batch);

    // Current model of filters takes a set of events and returns any events to add.
    Collection<Event> process(Collection<Event> events);
}
