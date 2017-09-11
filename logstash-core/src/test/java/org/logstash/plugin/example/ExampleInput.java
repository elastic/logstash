package org.logstash.plugin.example;

import org.logstash.Event;
import org.logstash.plugin.ConstructingObjectParser;
import org.logstash.plugin.Input;
import org.logstash.plugin.Plugin;

import javax.net.ssl.SSLContext;
import java.util.Collection;
import java.util.Collections;
import java.util.function.Consumer;

public class ExampleInput implements Input, Plugin {
    static final ConstructingObjectParser<ExampleInput> EXAMPLE = new ConstructingObjectParser<>(args -> new ExampleInput((int) args[0]));

    static {
        // Pass an integer named "port" as the first constructor argument.
        EXAMPLE.integer("port");

        /*
         * Have a single 'tls' setting that configures an object.
         *
         * The intent here is to be able to box a component (such as TLS) in a way that can be reused among plugins.
         *
         * In this example, we have 'example' input having a 'tls' setting, and this would look like this
         * in the Logstash config:
         *
         * input {
         *   example {
         *     port => 12345
         *     tls => {
         *       truststore => "/path/to/trust"
         *       key => "/path/to/private.key"
         *       certificate => "/path/to/server.crt"
         *       ciphers => [ "some", "specific", "ciphers" ]
         *     }
         *   }
         * }
         */
        EXAMPLE.object("tls", ExampleInput::setTLS, SSLContextConstructor.TLS);
    }

    private SSLContext context;

    public SSLContext getTLS() {
        return context;
    }

    void setTLS(SSLContext context) {
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
