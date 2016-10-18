package org.logstash.config.pipeline;

import org.logstash.config.ir.DSL;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.PluginDefinition;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.PluginVertex;
import org.logstash.config.ir.graph.SpecialVertex;
import org.logstash.config.ir.graph.Vertex;

import java.util.List;

/**
 * Created by andrewvc on 9/20/16.
 */
public class Pipeline {
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
        graph = DSL.graph();

        // We don't really care about the edges in the input section, we just want the vertices as roots
        for (Vertex inV : inputSection.getVertices()) {
            if (inV instanceof PluginVertex) {
                graph.addVertex(inV);
            } else {
                throw new InvalidIRException("Only plugin vertices are allowed in input sections!");
            }
        }

        // Connect all the input vertices out to the queue
        queue = new SpecialVertex(SpecialVertex.Type.QUEUE);
        graph.extend(queue);

        // Now we connect the queue to the root of the filter section
        graph.extend(filterSection);

        // Now we connect the leaves (and partial leaves) of the graph
        // which should all be filters (unless no filters are defined)
        // to the special filterOut node
        filterOut = new SpecialVertex(SpecialVertex.Type.FILTER_OUT);
        graph.extend(filterOut);

        // Finally, connect the filter out node to all the outputs
        graph.extend(outputSection);
    }

    public List<Vertex> getPostQueue() throws InvalidIRException {
    return graph.getSortedVerticesAfter(queue);
}

    public List<PluginVertex> getInputPluginVertices() {
        return graph.getPluginVertices(PluginDefinition.Type.INPUT);
    }

    public List<PluginVertex> getFilterPluginVertices() {
        return graph.getPluginVertices(PluginDefinition.Type.FILTER);
    }

    public List<PluginVertex> getOutputPluginVertices() {
        return graph.getPluginVertices(PluginDefinition.Type.OUTPUT);
    }

    @Override
    public String toString() {
        String summary = String.format("[Pipeline] Inputs: %d Filters: %d Outputs %d",
                getInputPluginVertices().size(),
                getFilterPluginVertices().size(),
                getOutputPluginVertices().size());
        return summary + "\n" + graph.toString();
    }

    public String toRubyString() {
        return "";
    }
}
