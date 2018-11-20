package org.logstash.execution;

import java.io.PrintStream;
import java.util.Collection;
import java.util.Collections;
import java.util.concurrent.CountDownLatch;
import org.logstash.Event;
import org.logstash.execution.plugins.PluginConfigSpec;

/**
 * A Logstash Pipeline Output.
 */
public interface Output extends LsPlugin {

    /**
     * Outputs Collection of {@link Event}.
     * @param events Events to Output
     */
    void output(Collection<Event> events);

    void stop();

    void awaitStop() throws InterruptedException;

    @LogstashPlugin(name = "output")
    final class StreamOutput implements Output {

        private final PrintStream output;

        private volatile boolean stopped;

        private final CountDownLatch done = new CountDownLatch(1);

        /**
         * Required Constructor Signature only taking a {@link LsConfiguration}.
         * @param configuration Logstash Configuration
         * @param context Logstash Context
         */
        public StreamOutput(final LsConfiguration configuration, final LsContext context) {
            this.output = new PrintStream(System.out);
        }

        @Override
        public void output(final Collection<Event> events) {
            try {

            } finally {
                stopped = true;
                done.countDown();
            }
        }

        @Override
        public void stop() {
            output.close();
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
