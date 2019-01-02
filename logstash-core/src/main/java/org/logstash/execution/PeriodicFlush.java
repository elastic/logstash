package org.logstash.execution;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

@SuppressWarnings("try")
public final class PeriodicFlush implements AutoCloseable {

    private static final Logger LOGGER = LogManager.getLogger(PeriodicFlush.class);

    private final ScheduledExecutorService executor = Executors.newSingleThreadScheduledExecutor(
        r -> new Thread(r, "logstash-pipeline-flush")
    );

    private final AtomicBoolean flushRequested;

    private final AtomicBoolean flushing;

    public PeriodicFlush(final AtomicBoolean flushRequested, final AtomicBoolean flushing) {
        this.flushRequested = flushRequested;
        this.flushing = flushing;
    }

    public void start() {
        executor.scheduleAtFixedRate(() -> {
            if (flushing.compareAndSet(false, true)) {
                LOGGER.debug("Pushing flush onto pipeline.");
                flushRequested.set(true);
            }
        }, 0L, 5L, TimeUnit.SECONDS);
    }

    @Override
    public void close() throws InterruptedException {
        executor.shutdown();
        if (!executor.awaitTermination(10L, TimeUnit.SECONDS)) {
            throw new IllegalStateException("Failed to stop period flush action.");
        }
    }
}
