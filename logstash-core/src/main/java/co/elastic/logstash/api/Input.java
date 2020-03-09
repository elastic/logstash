package co.elastic.logstash.api;

import java.util.Map;
import java.util.function.Consumer;

/**
 * Logstash Java input interface. Inputs produce events that flow through the Logstash event pipeline. Inputs are
 * flexible and may produce events through many different mechanisms including:
 *
 * <ul>
 *     <li>a pull mechanism such as periodic queries of external database</li>
 *     <li>a push mechanism such as events sent from clients to a local network port</li>
 *     <li>a timed computation such as a heartbeat</li>
 * </ul>
 *
 * or any other mechanism that produces a useful stream of events. Event streams may be either finite or infinite.
 * Logstash will run as long as any one of its inputs is still producing events.
 */
public interface Input extends Plugin {

    /**
     * Start the input and begin pushing events to the supplied {@link Consumer} instance. If the input produces
     * an infinite stream of events, this method should loop until a {@link #stop()} request is made. If the
     * input produces a finite stream of events, this method should terminate when the last event in the stream
     * is produced.
     * @param writer Consumer to which events should be pushed
     */
    void start(Consumer<Map<String, Object>> writer);

    /**
     * Notifies the input to stop producing events. Inputs stop both asynchronously and cooperatively. Use the
     * {@link #awaitStop()} method to block until the input has completed the stop process.
     */
    void stop();

    /**
     * Blocks until the input has stopped producing events. Note that this method should <b>not</b> signal the
     * input to stop as the {@link #stop()} method does.
     * @throws InterruptedException On Interrupt
     */
    void awaitStop() throws InterruptedException;

}
