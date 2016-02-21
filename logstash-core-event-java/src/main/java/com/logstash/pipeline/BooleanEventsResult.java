package com.logstash.pipeline;
import com.logstash.Event;
import java.util.LinkedList;
import java.util.List;

/**
 * Created by andrewvc on 2/26/16.
 */
public class BooleanEventsResult {
    private final List<Event> trueEvents;
    private final List<Event> falseEvents;

    public BooleanEventsResult() {
        this.trueEvents = new LinkedList<>();
        this.falseEvents = new LinkedList<>();
    }

    public BooleanEventsResult(List<Event> trueEvents, List<Event> falseEvents) {
        this.trueEvents = trueEvents;
        this.falseEvents = falseEvents;
    }

    public List<Event> getTrueEvents() {
        return trueEvents;
    }

    public List<Event> getFalseEvents() {
        return falseEvents;
    }


}
