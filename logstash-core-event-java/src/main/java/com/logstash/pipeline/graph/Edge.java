package com.logstash.pipeline.graph;

import java.util.Optional;
import java.util.function.Predicate;

/**
 * Created by andrewvc on 2/24/16.
 */
public class Edge {
    private final Vertex from;
    private final Vertex to;
    private final Condition condition;


    public Edge(Vertex from, Vertex to, Condition condition) {
        this.from = from;
        this.to = to;
        this.condition = condition;
    }

    public Vertex getFrom() {
        return from;
    }

    public Vertex getTo() {
        return to;
    }

    public boolean isCondition() {
        return this.condition != null;
    }

    public Condition getCondition() {
        return this.condition;
    }
}
