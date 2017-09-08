package org.logstash.plugin.example;

import org.logstash.Event;
import org.logstash.plugin.ConstructingObjectParser;
import org.logstash.plugin.Input;
import org.logstash.plugin.Plugin;

import java.util.Collection;
import java.util.Collections;
import java.util.function.Consumer;

class ExampleInput implements Input, Plugin {
    private static final ConstructingObjectParser<ExampleInput> EXAMPLE = new ConstructingObjectParser("example", () -> new ExampleInput());

    static {
        EXAMPLE.declareInteger("port", ExampleInput::setPort);
    }

    private int port;

    public ConstructingObjectParser<? extends Input> getInputs() {
        return EXAMPLE;
    }

    void setPort(int port) {
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
