package org.logstash.plugin;

import org.logstash.Event;

import java.util.Collection;
import java.util.function.Consumer;

/**
 * A Logstash input plugin.
 * <p>
 * Input plugins produce events intended given to Processors.
 * <p>
 * Inputs will generally run forever until there is some terminating condition such as a pipeline shutdown.
 */
public interface Input {
    /**
     * This is the main method for the input.
     *
     * Acknowledging Data:
     * <p>
     * When `consumer.accept(...)` returns, the given Events have been successfully written into the consumer, and it is now
     * safe to acknowledge these events to the upstream data source. The consumer is generally the Logstash internal queue,
     * such as the persistent queue.
     *
     * * for any request-response plugins, you should only respond *after* consumer.accept() has returned.
     * * for any protocols with acknowledgements, you should only acknowledge *after* consumer.accept() has returned.
     *
     * @param consumer Send batches of events with consumer.accept(batch).
     */
    void run(Consumer<Collection<Event>> consumer);

    /**
     * Initiate and complete shutdown of this input.
     *
     * This method will be called when any of the following occur:
     *   * Logstash is shutting down
     *   * The pipeline containing this input is being terminated.
     *
     * Note: This method will be called from a separate thread than the one executing the `run` method.
     *
     */
    void shutdown();
}
