package org.logstash.config.ir.graph;

import org.logstash.config.ir.ISourceComponent;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.PluginDefinition;
import org.logstash.config.ir.SourceMetadata;

import java.util.*;
import java.util.function.Consumer;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Created by andrewvc on 9/15/16.
 */
public class Graph implements ISourceComponent {
    private final Set<Vertex> vertices = new HashSet<>();
    private final Set<Edge> edges = new HashSet<>();

    public Graph(Collection<Vertex> vertices, Collection<Edge> edges) throws InvalidIRException {
        this.vertices.addAll(vertices);
        this.edges.addAll(edges);
        validate();
    }

    public Graph() {
    }

    public static Graph empty() {
        return new Graph();
    }

    public Graph addVertex(Vertex v) throws InvalidIRException {
        this.vertices.add(v);
        this.refresh();
        return this;
    }

    public void merge(Graph otherGraph) throws InvalidIRException {
        this.vertices.addAll(otherGraph.getVertices());
        this.edges.addAll(otherGraph.edges);
        this.refresh();
    }

    /*
      Attach another graph's nodes to this one by connection this graph's leaves to
      the other graph's root
    */
    public Graph threadLeavesInto(Graph otherGraph) throws InvalidIRException {
        if (otherGraph.getVertices().size() == 0) return this;

        // Build these lists here since we do mutate the graph in place later
        // This isn't strictly necessary, but makes things less confusing
        Collection<Vertex> fromLeaves = getLeaves();
        Collection<Vertex> toRoots = otherGraph.getRoots();

        if (this.isEmpty()) {
            this.merge(otherGraph);
            return this;
        }

        threadLeavesInto(fromLeaves, toRoots);

        return this;
    }

    public Graph threadLeavesInto(Vertex... otherVertex) throws InvalidIRException {
        threadLeavesInto(this.getPartialLeaves(), Arrays.asList(otherVertex));
        return this;
    }

    private void threadLeavesInto(Collection<Vertex> fromLeaves, Collection<Vertex> toVertices) throws InvalidIRException {
        for (Vertex leaf : fromLeaves) {
            for (Edge.EdgeFactory unusedEf : leaf.getUnusedOutgoingEdgeFactories()) {
                for (Vertex toVertex : toVertices) {
                    this.threadVertices(unusedEf, leaf, toVertex);
                }
            }
        }
    }

    public Graph threadVertices(Edge.EdgeFactory edgeFactory, Vertex... argVertices) throws InvalidIRException {
        Collection<Edge> newEdges = Edge.threadVertices(edgeFactory, argVertices);

        for (Edge edge : newEdges) {
            this.vertices.add(edge.getFrom());
            this.vertices.add(edge.getTo());
            this.edges.add(edge);
        }

        refresh();

        return this;
    }

    public Graph threadVertices(boolean bool, Vertex... vertices) throws InvalidIRException {
        Edge.EdgeFactory factory = new BooleanEdge.BooleanEdgeFactory(bool);
        return threadVertices(factory, vertices);
    }

    public Graph threadVertices(Vertex... vertices) throws InvalidIRException {
        return threadVertices(new PlainEdge.PlainEdgeFactory(), vertices);
    }

    // Many of the operations we perform involve modifying one graph but adding vertices/edges
    // from another. This method ensures that all the vertices/edges we know about having been pulled into
    // this graph. Methods in this class that add or remove externally provided vertices/edges
    // should call this method to ensure that the rest of the graph these items depend on are pulled
    // in.
    public void refresh() throws InvalidIRException {
        walkEdges(e -> {
            this.edges.add(e);
            this.vertices.add(e.getTo());
            this.vertices.add(e.getFrom());
        });

        walkVertices(v -> {
            this.vertices.add(v);
            this.edges.addAll(v.getIncomingEdges());
            this.edges.addAll(v.getOutgoingEdges());
        });

        this.validate();
    }

    public void validate() throws InvalidIRException {
        if (this.getVertices().stream().noneMatch(Vertex::isLeaf)) {
            throw new InvalidIRException("Graph has no leaf vertices!" + this.toString());
        }

        this.getSortedVertices();
    }

    public void walkVertices(Consumer<Vertex> consumer) {
        for (Vertex vertex : this.getRoots()) {
            walkVertices(consumer, vertex);
        }
    }

    public void walkVertices(Consumer<Vertex> consumer, Vertex vertex) {
        vertex.outgoingVertices().forEach(v -> {
            consumer.accept(v);
            walkVertices(consumer, v);
        });
    }

    // Walk the graph, visiting each edge on it with the provided Consumer<Edge>
    public void walkEdges(Consumer<Edge> consumer) {
        // Avoid stream interface to avoid concurrency issues if a new root is added
        // since streams are lazy you can't mutate the graph while walking it with a
        // stream. Using this iterative approach we can allow such operations.
        for (Vertex root : this.getRoots()) {
            walkEdges(consumer, root);
        }
    }

    private void walkEdges(Consumer<Edge> consumer, Vertex vertex) {
       vertex.outgoingEdges().forEach(e -> {
           consumer.accept(e);
           walkEdges(consumer,e.getTo());
       });
    }

    public Stream<Vertex> roots() {
        return vertices.stream().filter(Vertex::isRoot);
    }

    public List<Vertex> getRoots() {
        return roots().collect(Collectors.toList());
    }

    // Vertices which are partially leaves in that they support multiple
    // outgoing edge types but only have one or fewer attached
    public Stream<Vertex> partialLeaves() {
        return vertices.stream().filter(Vertex::isPartialLeaf);
    }

    public Collection<Vertex> getPartialLeaves() {
        return partialLeaves().collect(Collectors.toList());
    }

    public Stream<Vertex> leaves() {
        return vertices.stream().filter(Vertex::isLeaf);
    }

    public Collection<Vertex> getLeaves() {
        return leaves().collect(Collectors.toList());
    }

    public Set<Vertex> getVertices() {
        return vertices;
    }

    public Set<Edge> getEdges() {
        return edges;
    }

    public String toString() {
        Stream<Edge> edgesToFormat;
        try {
            edgesToFormat = getSortedEdges().stream();
        } catch (InvalidIRException e) {
            edgesToFormat = edges.stream();
        }

        String edgelessVerticesStr;
        if (this.isolatedVertices().count() > 0) {
            edgelessVerticesStr = "\n== Vertices Without Edges ==\n" +
                    this.isolatedVertices().map(Vertex::toString).collect(Collectors.joining("\n"));
        } else {
            edgelessVerticesStr = "";
        }

        return "<GRAPH>\n" +
                edgesToFormat.map(Edge::toString).collect(Collectors.joining("\n")) +
                edgelessVerticesStr +
                "\n</GRAPH>";
    }

    public Stream<Vertex> isolatedVertices() {
        return this.getVertices().stream().filter(v -> v.getOutgoingEdges().isEmpty() && v.getIncomingEdges().isEmpty());
    }

    // Uses Kahn's algorithm to do a topological sort and detect cycles
    public List<Vertex> getSortedVertices() throws InvalidIRException {
        if (this.edges.size() == 0) return new ArrayList(this.vertices);

        List<Vertex> sorted = new ArrayList<>(this.vertices.size());

        Deque<Vertex> pending = new LinkedList<>();
        pending.addAll(this.getRoots());

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
        if (this.edges.stream().noneMatch(traversedEdges::contains)) {
            throw new InvalidIRException("Graph has cycles, is not a DAG! " + this.edges);
        }

        return sorted;
    }

    public List<Edge> getSortedEdges() throws InvalidIRException {
        return getSortedVertices().stream().
                flatMap(Vertex::outgoingEdges).
                collect(Collectors.toList());
    }

    public List<Vertex> getSortedVerticesBefore(Vertex end) throws InvalidIRException {
        return getSortedVerticesBetween(null, end);
    }

    public List<Vertex> getSortedVerticesAfter(Vertex start) throws InvalidIRException {
        return getSortedVerticesBetween(start, null);
    }

    public List<Vertex> getSortedVerticesBetween(Vertex start, Vertex end) throws InvalidIRException {
        List<Vertex> sortedVertices = getSortedVertices();

        int startIndex = start == null ? 0 : sortedVertices.indexOf(start);
        int endIndex = end == null ? sortedVertices.size() : sortedVertices.indexOf(end);

        return sortedVertices.subList(startIndex+1, endIndex);
    }

    @Override
    public boolean sourceComponentEquals(ISourceComponent sourceComponent) {
        if (sourceComponent == this) return true;
        if (sourceComponent instanceof Graph) {
            Graph otherG = (Graph) sourceComponent;
            if (otherG.getVertices().size() != this.getVertices().size()) return false;

            boolean edgesEqual = this.getEdges().stream().
                    allMatch(e -> otherG.getEdges().stream().anyMatch(oe -> oe.sourceComponentEquals(e)));

            // We need to check vertices separately because there may be unconnected vertices
            boolean verticesEqual = this.getVertices().stream().
                    allMatch(v -> otherG.getVertices().stream().anyMatch(ov -> ov.sourceComponentEquals(v)));

            return edgesEqual && verticesEqual;
        }
        return false;
    }

    // returns true if this graph has a .sourceComponentEquals equivalent edge
    public boolean hasEquivalentEdge(Edge otherE) {
        return this.getEdges().stream().anyMatch(e -> e.sourceComponentEquals(otherE));
    }


    public class DiffResult {
        public Collection<Edge> getRemovedEdges() {
            return removedEdges;
        }

        public Collection<Edge> getAddedEdges() {
            return addedEdges;
        }

        private final Collection<Edge> removedEdges;
        private final Collection<Edge> addedEdges;

        public DiffResult(Collection<Edge> removed, Collection<Edge> added) {
            this.removedEdges = removed;
            this.addedEdges = added;
        }

        public String toString() {
            return "Diff Result (-" + removedEdges.size() + ",+" + addedEdges.size() + ")\n" +
                    removedEdges.stream().map(e -> "-" + e.toString()).collect(Collectors.joining("\n")) +
                    "\n" +
                    addedEdges.stream().map(e -> "+" + e.toString()).collect(Collectors.joining("\n"));
        }
    }

    public DiffResult diff(Graph o) {
       List<Edge> removedEdges = this.getEdges().stream().filter(e -> !o.hasEquivalentEdge(e)).collect(Collectors.toList());
       List<Edge> addedEdges = o.getEdges().stream().filter(e -> !this.hasEquivalentEdge(e)).collect(Collectors.toList());
        return new DiffResult(removedEdges, addedEdges);
    }

    @Override
    public SourceMetadata getMeta() {
        return null;
    }

    public boolean isEmpty() {
        return (this.getVertices().size() == 0);
    }

    public Graph threadToGraph(BooleanEdge.BooleanEdgeFactory edgeFactory, Vertex v, Graph otherGraph) throws InvalidIRException {
        if (otherGraph.getVertices().size() == 0) return this;

        for (Vertex otherRoot : otherGraph.getRoots()) {
            this.threadVertices(edgeFactory, v, otherRoot);
        }

        return this;
    }

    public Stream<Vertex> vertices() {
        return this.vertices.stream();
    }

    public Stream<Edge> edges() {
        return this.edges.stream();
    }
}
