package co.elastic.logstash.api;

import co.elastic.logstash.api.Plugin;
import org.logstash.Event;

import java.util.Collection;

/**
 * A Logstash Pipeline Output.
 */
public interface Output extends Plugin {

    /**
     * Outputs Collection of {@link Event}.
     * @param events Events to Output
     */
    void output(Collection<Event> events);

    void stop();

    void awaitStop() throws InterruptedException;

}
