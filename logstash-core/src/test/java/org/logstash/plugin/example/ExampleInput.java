package org.logstash.plugin.example;

import org.logstash.Event;
import org.logstash.plugin.ConstructingObjectParser;
import org.logstash.plugin.Input;
import org.logstash.plugin.Plugin;

import java.util.Collection;
import java.util.Collections;
import java.util.function.Consumer;

public class ExampleInput implements Input, Plugin {
    static final ConstructingObjectParser<ExampleInput> EXAMPLE = new ConstructingObjectParser<>(args -> new ExampleInput((int) args[0]));

    static {
        // Pass an integer named "port" as the first constructor argument.
        EXAMPLE.integer("port");
        EXAMPLE.string("setting", ExampleInput::setGreeting);
    }

    private int port;

    // A setting with a default value.
    private String greeting = "Hello";

    private ExampleInput(int port) {
        this.port = port;
    }

    private void setGreeting(String greeting) {
        this.greeting = greeting;
    }

    @Override
    public void run(Consumer<Collection<Event>> consumer) {
        Event event = new Event();
        event.setField("message", "Hello from Example");
        event.setField("port", port);
        Collection<Event> events = Collections.singleton(event);
        consumer.accept(events);
    }
}
