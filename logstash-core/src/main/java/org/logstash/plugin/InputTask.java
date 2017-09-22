package org.logstash.plugin;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.Event;

import java.util.Collection;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

public class InputTask {
    private static final Logger logger = LogManager.getLogger();
    private final Input input;
    private Thread thread;

    public InputTask(Input input, Consumer<Collection<Event>> consumer) {
        this.input = input;
        thread = new Thread(() -> input.run(consumer));
    }

    public void start() {
        thread.start();
    }

    public void awaitTermination(long timeout, TimeUnit unit) {
        try {
            thread.join(unit.toMillis(timeout));
        } catch (InterruptedException e) {
            // This isn't expected to occur.
            logger.error("awaitTermination was interrupted", e);
        }
    }


    public void shutdown() {
        if (thread.isAlive()) {
            thread.interrupt();
            input.shutdown();
        }
    }
}
