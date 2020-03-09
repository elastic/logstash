package co.elastic.logstash.api;

import java.util.Collection;

/**
 * Logstash Java output interface. Outputs may send events to local sinks such as the console or a file or to remote
 * systems such as Elasticsearch or other external systems.
 */
public interface Output extends Plugin {

    /**
     * Outputs Collection of {@link Event}.
     * @param events Events to be sent through the output.
     */
    void output(Collection<Event> events);

    /**
     * Notifies the output to stop sending events. Outputs with connections to external systems or other resources
     * requiring cleanup should perform those tasks upon a stop notification. Outputs stop both asynchronously and
     * cooperatively. Use the {@link #awaitStop()} method to block until an output has completed the stop process.
     */
    void stop();

    /**
     * Blocks until the output has stopped sending events. Note that this method should <b>not</b> signal the
     * output to stop as the {@link #stop()} method does.
     * @throws InterruptedException On Interrupt
     */
    void awaitStop() throws InterruptedException;

}
