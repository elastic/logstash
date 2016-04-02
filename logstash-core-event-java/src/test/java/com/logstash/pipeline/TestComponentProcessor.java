package com.logstash.pipeline;

import com.logstash.Event;
import com.logstash.pipeline.graph.Condition;
import com.logstash.pipeline.graph.Vertex;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Created by andrewvc on 2/22/16.
 */
public class TestComponentProcessor implements ComponentProcessor {
    @Override
    public ArrayList<Event> process(Component component, List<Event> events) {
        return new ArrayList<Event>();
    }

    @Override
    public BooleanEventsResult processCondition(Condition condition, List<Event> events) {
        return new BooleanEventsResult();
    }

    @Override
    public void flush(Component c, boolean shutdown) {

    }
    @Override
    public void setup(Component component) {

    }
}
