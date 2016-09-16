package org.logstash.config.ir.graph;

import org.logstash.config.ir.InvalidIRException;

import java.util.Collection;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;
import java.util.function.Consumer;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Created by andrewvc on 9/15/16.
 */
public class Graph {
    private final Set<Vertex> vertices = new HashSet<>();
    private final Set<Edge> edges = new HashSet<>();

    public static Graph empty() {
        return new Graph();
    }

    public Graph(Collection<Vertex> vertices, Collection<Edge> edges) {
        this.vertices.addAll(vertices);
        this.edges.addAll(edges);
    }

    public Graph() {
    }

    public Graph addVertex(Vertex v) {
        this.vertices.add(v);
        return this;
    }

    public Graph addByThreading(Edge.EdgeFactory edgeFactory, Vertex... vertices) {
        Collection<Edge> newEdges = Edge.threadVertices(edgeFactory, vertices);
        addEdges(newEdges);

        return this;
    }

    public Graph addByThreading(Vertex... vertices) {
        return addByThreading(new Edge.EdgeFactory(), vertices);
    }

    private void addEdge(Edge e) {
        this.getEdges().add(e);
        refresh();
    }

    public void refresh() {
        walk(e -> {
            this.edges.add(e);
            this.vertices.add(e.getTo());
            this.vertices.add(e.getFrom());
        });
    }

    public void walk(Consumer<Edge> consumer) {
        for (Vertex root : roots().collect(Collectors.toList())) {
            walk(consumer, root);
        }
    }

    // TODO check for cycles with a topological sort
    private void walk(Consumer<Edge> consumer, Vertex vertex) {
        for (Edge edge : vertex.getOutgoingEdges()) {
            consumer.accept(edge);
            walk(consumer, edge.getTo());
        }
    }

    public Graph addEdges(Collection<Edge> edges) {
        this.edges.addAll(edges);

        this.edges.stream().forEach(edge -> {
            this.vertices.add(edge.getTo());
            this.vertices.add(edge.getFrom());
        });

        refresh();

        return this;
    }

    public Optional<Vertex> root() throws InvalidIRException {
        refresh();
        if ( roots().count() > 1 ) {
            throw new InvalidIRException("Expected one root, got multiple!");
        }
        return roots().findFirst();
    }

    public Stream<Vertex> roots() {
        return vertices.stream().filter(Vertex::isRoot);
    }

    public Stream<Vertex> leaves() {
        return vertices.stream().filter(Vertex::isLeaf);
    }

    public Set<Vertex> getVertices() {
        return vertices;
    }

    public Set<Edge> getEdges() {
        return edges;
    }

    public String toString() {
        return "<<< GRAPH >>>\n" +
                getEdges().stream().map(Edge::toString).collect(Collectors.joining("\n")) +
                "\n<<< /GRAPH >>>";
    }
}
