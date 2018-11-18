package org.logstash.execution;

import java.util.Collection;
import java.util.Collections;
import java.util.Scanner;
import java.util.concurrent.CountDownLatch;
import org.logstash.execution.plugins.PluginConfigSpec;
import org.logstash.execution.queue.QueueWriter;

/**
 * A Logstash Pipeline Input pushes to a {@link QueueWriter}.
 */
public interface Input extends LsPlugin {

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

    @LogstashPlugin(name = "java-one-input-event")
    final class OneInputEvent implements Input {

        public OneInputEvent(final LsConfiguration configuration, final LsContext context) {
            // do nothing
        }

        @Override
        public void start(QueueWriter writer) {
            writer.push(Collections.singletonMap("oneEvent", "isDone"));
        }

        @Override
        public void stop() {

        }

        @Override
        public void awaitStop() throws InterruptedException {

        }

        @Override
        public Collection<PluginConfigSpec<?>> configSchema() {
            return Collections.EMPTY_LIST;
        }
    }

    @LogstashPlugin(name = "stream")
    final class StreamInput implements Input {

        private Scanner inpt;

        private final CountDownLatch done = new CountDownLatch(1);

        private volatile boolean stopped;

        /**
         * Required Constructor Signature only taking a {@link LsConfiguration}.
         * @param configuration Logstash Configuration
         * @param context Logstash Context
         */
        public StreamInput(final LsConfiguration configuration, final LsContext context) {
            // Do whatever
            System.out.println("Stream instantiated");
        }

        @Override
        public void start(final QueueWriter writer) {
            inpt = new Scanner(System.in, "\n");
            try {
                while (!stopped && inpt.hasNext()) {
                    final String message = inpt.next();
                    writer.push(Collections.singletonMap("message", message));
                }
            } finally {
                stopped = true;
                done.countDown();
            }
        }

        @Override
        public void stop() {
            stopped = true;
        }

        @Override
        public void awaitStop() throws InterruptedException {
            done.await();
        }

        @Override
        public Collection<PluginConfigSpec<?>> configSchema() {
            return Collections.emptyList();
        }
    }
}
