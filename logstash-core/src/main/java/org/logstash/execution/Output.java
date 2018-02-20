package org.logstash.execution;

import java.io.IOException;
import java.io.PrintStream;
import java.util.Collection;
import java.util.Collections;
import java.util.concurrent.CountDownLatch;
import org.logstash.Event;

/**
 * A Logstash Pipeline Output consumes a {@link QueueReader}.
 */
public interface Output extends LsPlugin {

    /**
     * Polls events from event reader and runs output action.
     * @param reader Reader to poll events from.
     */
    void output(QueueReader reader);

    void stop();

    void awaitStop() throws InterruptedException;

    @LogstashPlugin(name = "output")
    final class StreamOutput implements Output {

        private final PrintStream outpt;

        private volatile boolean stopped;

        private final CountDownLatch done = new CountDownLatch(1);

        /**
         * Required Constructor Signature only taking a {@link LsConfiguration}.
         * @param configuration Logstash Configuration
         * @param context Logstash Context
         */
        public StreamOutput(final LsConfiguration configuration, final LsContext context) {
            this.outpt = new PrintStream(System.out);
        }

        @Override
        public void output(final QueueReader reader) {
            final Event event = new Event();
            try {
                long sequence = reader.poll(event);
                while (!stopped && sequence > -1L) {
                    try {
                        outpt.println(event.toJson());
                        reader.acknowledge(sequence);
                    } catch (final IOException ex) {
                        throw new IllegalStateException(ex);
                    }
                    sequence = reader.poll(event);
                }
            } finally {
                stopped = true;
                done.countDown();
            }
        }

        @Override
        public void stop() {
            outpt.close();
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
