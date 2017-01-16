package org.logstash.config.ir.graph.algorithms;

import org.logstash.config.ir.graph.Edge;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.Vertex;

import java.util.*;

/**
 * Created by andrewvc on 1/7/17.
 */
public class TopologicalSort {
    public static class UnexpectedGraphCycleError extends Exception {
        UnexpectedGraphCycleError(Graph g) {
            super("Graph has cycles, is not a DAG! " + g);
        }
    }

    // Uses Kahn's algorithm to do a topological sort and detect cycles
    public static List<Vertex> sortVertices(Graph g) throws UnexpectedGraphCycleError {
        if (g.getEdges().size() == 0) return new ArrayList<>(g.getVertices());

        List<Vertex> sorted = new ArrayList<>(g.getVertices().size());

        Deque<Vertex> pending = new LinkedList<>();
        pending.addAll(g.getRoots());

        Set<Edge> traversedEdges = new HashSet<>();

        while (!pending.isEmpty()) {
            Vertex currentVertex = pending.removeFirst();
            sorted.add(currentVertex);

            currentVertex.getOutgoingEdges().forEach(edge -> {
                traversedEdges.add(edge);
                Vertex toVertex = edge.getTo();
                if (toVertex.getIncomingEdges().stream().allMatch(traversedEdges::contains)) {
                    pending.add(toVertex);
                }
            });
        }

        // Check for cycles
        if (g.edges().noneMatch(traversedEdges::contains)) {
            throw new UnexpectedGraphCycleError(g);
        }

        return sorted;
    }

}
