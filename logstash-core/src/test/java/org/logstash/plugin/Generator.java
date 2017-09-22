package org.logstash.plugin;

import org.logstash.Event;

import java.util.Collection;
import java.util.Collections;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

class Generator implements Input {
    private final ScheduledExecutorService service = Executors.newSingleThreadScheduledExecutor();
    private volatile int counter = 0;

    private void generate(Consumer<Collection<Event>> consumer) {
        counter++;
        Event event = new Event();
        event.setField("value", counter);
        consumer.accept(Collections.singleton(event));
    }

    @Override
    public void run(Consumer<Collection<Event>> consumer) {
        counter = 0;
        service.scheduleAtFixedRate(() -> generate(consumer), 0, 10, TimeUnit.MILLISECONDS);

        try {
            // Block forever.
            while (!service.awaitTermination(60, TimeUnit.SECONDS)) ;
        } catch (InterruptedException e) {
            // ignore, but we'll break out and call shutdown().
        } finally {
            shutdown();
        }
    }

    @Override
    public void shutdown() {
        service.shutdownNow();
    }
}
