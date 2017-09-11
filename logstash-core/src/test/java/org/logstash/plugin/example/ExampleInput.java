package org.logstash.plugin.example;

import org.logstash.Event;
import org.logstash.plugin.Input;
import org.logstash.plugin.Plugin;

import java.util.Collection;
import java.util.Collections;
import java.util.function.Consumer;

public class ExampleInput implements Input, Plugin {
    private TLSContext context;

    public TLSContext getTLS() {
        return context;
    }

    void setTLS(TLSContext context) {
        this.context = context;
    }

    private int port;

    void setPort(int port) {
        this.port = port;
    }

    public ExampleInput(int port) {
        this.port = port;
    }

    @Override
    public void run(Consumer<Collection<Event>> consumer) {
        Event event = new Event();
        event.setField("message", "Hello from Example");
        Collection<Event> events = Collections.singleton(event);
        consumer.accept(events);
    }
}
