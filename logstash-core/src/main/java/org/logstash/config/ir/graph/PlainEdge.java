package org.logstash.config.ir.graph;

import org.logstash.config.ir.ISourceComponent;
import org.logstash.config.ir.InvalidIRException;

/**
 * Created by andrewvc on 9/19/16.
 */
public class PlainEdge extends Edge {
    public static class PlainEdgeFactory extends Edge.EdgeFactory {
        @Override
        public Edge make(Vertex from, Vertex to) throws InvalidIRException {
           return new PlainEdge(from, to);
        }
    }

    public static PlainEdgeFactory factory = new PlainEdgeFactory();

    public PlainEdge(Vertex from, Vertex to) throws InvalidIRException {
        super(from, to);
    }



}
