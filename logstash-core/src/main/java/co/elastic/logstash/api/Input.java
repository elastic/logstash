package co.elastic.logstash.api;

import org.logstash.execution.queue.QueueWriter;

/**
 * A Logstash Pipeline Input pushes to a {@link QueueWriter}.
 */
public interface Input extends Plugin {

    /**
     * Start pushing {@link org.logstash.Event} to given {@link QueueWriter}.
     * @param writer Queue Writer to Push to
     */
    void start(QueueWriter writer);

    /**
     * Stop the input.
     * Stopping happens asynchronously, use {@link #awaitStop()} to make sure that the input has
     * finished.
     */
    void stop();

    /**
     * Blocks until the input execution has finished.
     * @throws InterruptedException On Interrupt
     */
    void awaitStop() throws InterruptedException;

}
