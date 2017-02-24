package org.logstash.config.ir;

import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.PluginVertex;
import org.logstash.config.ir.graph.SpecialVertex;
import org.logstash.config.ir.graph.Vertex;

import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Created by andrewvc on 9/20/16.
 */
public class Pipeline implements IHashable {
    public Graph getGraph() {
        return graph;
    }

    public SpecialVertex getQueue() {
        return queue;
    }

    public SpecialVertex getFilterOut() {
        return filterOut;
    }

    private final Graph graph;
    private final SpecialVertex queue;
    private final SpecialVertex filterOut;

    public Pipeline(Graph inputSection, Graph filterSection, Graph outputSection) throws InvalidIRException {
        Graph tempGraph = inputSection.copy(); // The input section are our roots, so we can import that wholesale

        // Connect all the input vertices out to the queue
        queue = new SpecialVertex(SpecialVertex.Type.QUEUE);
        tempGraph = tempGraph.chain(queue);

        // Now we connect the queue to the root of the filter section
        tempGraph = tempGraph.chain(filterSection);

        // Now we connect the leaves (and partial leaves) of the graph
        // which should all be filters (unless no filters are defined)
        // to the special filterOut node
        filterOut = new SpecialVertex(SpecialVertex.Type.FILTER_OUT);
        tempGraph = tempGraph.chain(filterOut);

        // Finally, connect the filter out node to all the outputs
        this.graph = tempGraph.chain(outputSection);
    }

    public List<Vertex> getPostQueue() throws InvalidIRException {
       return graph.getSortedVerticesAfter(queue);
    }

    public List<PluginVertex> getInputPluginVertices() {
        return getPluginVertices(PluginDefinition.Type.INPUT);
    }

    public List<PluginVertex> getFilterPluginVertices() {
        return getPluginVertices(PluginDefinition.Type.FILTER);
    }

    public List<PluginVertex> getOutputPluginVertices() {
        return getPluginVertices(PluginDefinition.Type.OUTPUT);
    }

    @Override
    public String toString() {
        String summary = String.format("[Pipeline] Inputs: %d Filters: %d Outputs %d",
                getInputPluginVertices().size(),
                getFilterPluginVertices().size(),
                getOutputPluginVertices().size());
        return summary + "\n" + graph.toString();
    }


    // Return plugin vertices by type
    public Stream<PluginVertex> pluginVertices(PluginDefinition.Type type) {
        return pluginVertices()
               .filter(v -> v.getPluginDefinition().getType().equals(type));
    }

    // Return plugin vertices by type
    public List<PluginVertex> getPluginVertices(PluginDefinition.Type type) {
        return pluginVertices(type).collect(Collectors.toList());
    }

    public List<PluginVertex> getPluginVertices() {
        return pluginVertices().collect(Collectors.toList());
    }

    public Stream<PluginVertex> pluginVertices() {
        return graph.vertices()
               .filter(v -> v instanceof PluginVertex)
               .map(v -> (PluginVertex) v);
    }

    @Override
    public String hashSource() {
        return this.graph.uniqueHash();
    }
}
