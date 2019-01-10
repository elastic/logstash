package co.elastic.logstash.api.v0;

import co.elastic.logstash.api.Plugin;
import org.logstash.Event;

import java.util.Collection;

/**
 * A Logstash Filter.
 */
public interface Filter extends Plugin {

    Collection<Event> filter(Collection<Event> events, FilterMatchListener matchListener);

}
