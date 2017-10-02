package org.logstash.plugin;

import org.logstash.Event;

import java.util.Iterator;

public interface Output {
    /**
     * Process a batch with the intent of sending the event externally.
     *
     * @param events the events to output.
     */
    void process(Batch batch);

    interface Batch extends Iterator<Event> {
        boolean hasNext();

        Event next();

        /**
         * Drop an event from the batch
         *
         * @param event
         */
        void drop(Event event);

        /**
         * Write an event to the dead letter queue.
         *
         * @param event
         * @param cause
         */
        void dlq(Event event, String cause);

    }

}
