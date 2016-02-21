package com.logstash.pipeline;

import com.logstash.Event;
import com.logstash.pipeline.graph.Condition;

import java.util.*;

/**
 * Created by andrewvc on 2/22/16.
 */
public interface ComponentProcessor {
    List<Event> process(Component component, List<Event> events);
    BooleanEventsResult processCondition(Condition condition, List<Event> events);
    void flush(Component c, boolean shutdown);
    void setup(Component component);
}
