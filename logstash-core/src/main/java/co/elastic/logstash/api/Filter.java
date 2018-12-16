package co.elastic.logstash.api;

import org.logstash.Event;

import java.util.Collection;

/**
 * A Logstash Filter.
 */
public interface Filter extends Plugin {

    Collection<Event> filter(Collection<Event> events);

}
