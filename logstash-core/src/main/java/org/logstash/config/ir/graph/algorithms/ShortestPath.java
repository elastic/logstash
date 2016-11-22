package org.logstash.config.ir.graph.algorithms;

import org.logstash.config.ir.graph.Vertex;

import java.security.cert.CollectionCertStoreParameters;
import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Created by andrewvc on 1/5/17.
 * This class isn't currently used anywhere, I wrote it for some code that is now removed, however, I'm sure it will be
 * useful shortly, so we should hold onto it for a while.
 */
public class ShortestPath {
    static class InvalidShortestPathArguments extends Exception {
        private final Collection<Vertex> invalidVertices;

        public InvalidShortestPathArguments(Collection<Vertex> invalidVertices) {
            super();
            this.invalidVertices = invalidVertices;

        }

        @Override
        public String getMessage() {
            String verticesMessage = invalidVertices.stream().map(Vertex::toString).collect(Collectors.joining(", "));
            return "Attempted to determine path for vertex that is not in the search space!" + verticesMessage;
        }
    }


    public static List<Vertex> shortestPath(Vertex from, Vertex to) throws InvalidShortestPathArguments {
        return shortestPath(from, Collections.singleton(to)).get(to);
    }

    public static Map<Vertex, List<Vertex>> shortestPath(Vertex from, Collection<Vertex> to) throws InvalidShortestPathArguments {
        return shortestPath(from, to, false);
    }

    // Finds the shortest paths to the specified vertices traversing edges backward using Dijkstra's algorithm.
    // The items in `to` must be ancestors of this Vertex!
    public static Map<Vertex, List<Vertex>> shortestReversePath(Vertex from, Collection<Vertex> to) throws InvalidShortestPathArguments {
        return shortestPath(from, to, true);
    }

    // Finds the shortest paths to the specified vertices using Dijkstra's algorithm.
    // The items in `to` must be ancestors of this Vertex!
    public static Map<Vertex, List<Vertex>> shortestPath(Vertex from, Collection<Vertex> to, boolean reverseSearch) throws InvalidShortestPathArguments {
        Map<Vertex, Integer> vertexDistances = new HashMap<>();
        Map<Vertex, Vertex> vertexPathPrevious = new HashMap<>();

        List<Vertex> pending = new ArrayList<>();
        Stream<Vertex> searchSpace = reverseSearch ? from.ancestors() : from.descendants();
        searchSpace.forEach((vertex) -> {
            pending.add(vertex);
            // Max value is an unknown distance
            // using this is more convenient and concise than null in later code
            vertexDistances.put(vertex, Integer.MAX_VALUE);
        });

        pending.add(from);
        vertexDistances.put(from, 0);

        Collection<Vertex> invalidVertices = to.stream().filter(v -> !pending.contains(v)).collect(Collectors.toList());
        if (!invalidVertices.isEmpty()) {
            throw new InvalidShortestPathArguments(invalidVertices);
        }

        while (!pending.isEmpty()) {
            Vertex current = pending.stream().min(Comparator.comparing(vertexDistances::get)).get();
            int currentDistance = vertexDistances.get(current);
            pending.remove(current);

            Stream<Vertex> toProcess = reverseSearch ? current.incomingVertices() : current.outgoingVertices();

            toProcess.forEach((v) -> {
                Integer curDistance = vertexDistances.get(v);
                int altDistance = currentDistance + 1; // Fixed cost per edge of 1
                if (altDistance < curDistance) {
                    vertexDistances.put(v, altDistance);
                    vertexPathPrevious.put(v, current);
                }
            });
        }

        Map<Vertex, List<Vertex>> result = new HashMap<>(to.size());

        for (Vertex toVertex : to) {
            int toVertexDistance = vertexDistances.get(toVertex);

            List<Vertex> path = new ArrayList<>(toVertexDistance+1);
            Vertex pathCurrentVertex = toVertex;
            while (pathCurrentVertex != from) {
                path.add(pathCurrentVertex);
                pathCurrentVertex = vertexPathPrevious.get(pathCurrentVertex);
            }
            path.add(from);
            Collections.reverse(path);
            result.put(toVertex, path);
        }

        return result;
    }

}
