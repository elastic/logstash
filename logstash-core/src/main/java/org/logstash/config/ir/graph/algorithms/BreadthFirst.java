package org.logstash.config.ir.graph.algorithms;

import org.logstash.config.ir.graph.Vertex;

import java.util.*;
import java.util.function.Consumer;
import java.util.stream.Stream;

/**
 * Created by andrewvc on 1/5/17.
 *
 */
public class BreadthFirst {
    public static BfsResult breadthFirst(Collection<Vertex> roots) {
        return breadthFirst(roots, false, null);
    }

    /* This isn't as pretty as the DFS search with its streaminess, but for our current uses we only really
    *  care about using this to get the calculated vertexDistances, so that's fine. */
    public static BfsResult breadthFirst(Collection<Vertex> roots,
                                        boolean reverse,
                                        Consumer<Map.Entry<Vertex, Integer>> consumer
                                        ) {
    Map<Vertex, Integer> vertexDistances = new HashMap<>();
    Map<Vertex, Vertex> vertexParents = new HashMap<>();

    Deque<Vertex> queue = new ArrayDeque<>(roots);
    roots.forEach(v -> vertexDistances.put(v, 0));

    while (!queue.isEmpty()) {
        Vertex currentVertex = queue.removeFirst();
        Integer currentDistance = vertexDistances.get(currentVertex);

        if (consumer != null) {
            consumer.accept(new AbstractMap.SimpleImmutableEntry<>(currentVertex, currentDistance));
        }

        Stream<Vertex> nextVertices = reverse ? currentVertex.incomingVertices() : currentVertex.outgoingVertices();
        nextVertices.forEach(nextVertex -> {
            if (vertexDistances.get(nextVertex) == null) {
                vertexDistances.put(nextVertex, currentDistance+1);
                vertexParents.put(nextVertex, currentVertex);
                queue.push(nextVertex);
            }
        });
    }

    return new BfsResult(vertexDistances, vertexParents);
}

    public static final class BfsResult {
        public final Map<Vertex, Integer> vertexDistances;
        private final Map<Vertex, Vertex> vertexParents;

        BfsResult(Map<Vertex, Integer> vertexDistances, Map<Vertex,Vertex> vertexParents) {
            this.vertexDistances = vertexDistances;
            this.vertexParents = vertexParents;
        }

        public Collection<Vertex> getVertices() {
            return vertexDistances.keySet();
        }
    }
}
