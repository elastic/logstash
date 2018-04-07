package org.logstash.execution.inputs;

import java.util.Collection;
import java.util.Collections;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicBoolean;
import org.logstash.execution.Input;
import org.logstash.execution.LogstashPlugin;
import org.logstash.execution.LsConfiguration;
import org.logstash.execution.LsContext;
import org.logstash.execution.plugins.PluginConfigSpec;
import org.logstash.execution.queue.QueueWriter;

@LogstashPlugin(name = "java-generator")
public final class JavaGenerator implements Input {

    private final AtomicBoolean running = new AtomicBoolean(false);

    private final CountDownLatch stopped = new CountDownLatch(1);

    public JavaGenerator(final LsConfiguration configuration, final LsContext context) {
    }

    @Override
    public void start(final QueueWriter writer) {
        try {
            while (running.get()) {
                writer.push(Collections.singletonMap("message", "some message text"));
            }
        } finally {
            stopped.countDown();
        }
    }

    @Override
    public void stop() {
        running.set(false);
    }

    @Override
    public void awaitStop() throws InterruptedException {
        stopped.await();
    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        return Collections.emptyList();
    }
}
