package co.elastic.logstash.api.v0;

import co.elastic.logstash.api.Plugin;
import org.logstash.Event;

import java.util.Collection;
import java.util.Collections;

/**
 * Logstash filter interface.
 */
public interface Filter extends Plugin {

    Collection<Event> filter(Collection<Event> events, FilterMatchListener matchListener);

    default Collection<Event> flush(FilterMatchListener matchListener) {
        return Collections.emptyList();
    }

    default boolean requiresFlush() {
        return false;
    }

    default boolean requiresPeriodicFlush() {
        return false;
    }

}
