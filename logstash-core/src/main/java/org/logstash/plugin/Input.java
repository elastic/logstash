package org.logstash.plugin;

import org.logstash.Event;

import java.util.Collection;
import java.util.concurrent.Callable;
import java.util.concurrent.Executors;
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
     * The method contract is as follows:
     * <p>
     * 1) When `Thread.interrupted()` is true, you MUST close all open resources and return.
     * 2) When this method returns, it is assumed all work for this input is completed.
     * 3) consumer.accept(...) may block
     * <p>
     * Acknowledging Data:
     * <p>
     * When `consumer.accept(...)` returns, the given Events have been successfully written into the consumer, and it is now
     * safe to acknowledge these events to the upstream data source. The consumer is generally the Logstash internal queue,
     * such as the persistent queue.
     *
     * @param consumer Send batches of events with consumer.accept(batch).
     */
    void run(Consumer<Collection<Event>> consumer);

    /**
     * Return this Input as a Callable for use with an ExecutorService.
     *
     * @param consumer the
     * @return A Callable which wraps the `run` method.
     */
    default Callable<Void> toCallable(Consumer<Collection<Event>> consumer) {
        return Executors.callable(() -> run(consumer), null);
    }
}
