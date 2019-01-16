package co.elastic.logstash.api;

import org.logstash.Event;

public interface FilterMatchListener {

    void filterMatched(Event e);
}
