package org.logstash.config.compiler.compiled;

import org.logstash.Event;
import org.logstash.config.ir.graph.Edge;

import java.util.List;
import java.util.Map;

/**
 * Created by andrewvc on 9/22/16.
 */
public interface ICompiledProcessor extends ICompiledVertex {
    Map<Edge, List<Event>> process(List<Event> events);
}
