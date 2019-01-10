package co.elastic.logstash.api.v0;

import org.logstash.Event;

public interface FilterMatchListener {

    void filterMatched(Event e);
}
