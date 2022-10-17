/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.config.ir;

import java.util.List;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.logstash.common.Util;
import org.logstash.config.ir.graph.*;

public final class PipelineIR implements Hashable {

    private final String uniqueHash;

    public Graph getGraph() {
        return graph;
    }

    public QueueVertex getQueue() {
        return queue;
    }

    private final Graph graph;

    private final QueueVertex queue;

    // Temporary until we have LIR execution
    // Then we will no longer need this property here
    private final String originalSource;

    public PipelineIR(Graph inputSection, Graph filterSection, Graph outputSection) throws InvalidIRException {
        this(inputSection, filterSection, outputSection, null);
    }

    public PipelineIR(Graph inputSection, Graph filterSection, Graph outputSection, String originalSource) throws InvalidIRException {
        this.originalSource = originalSource;

        Graph tempGraph = inputSection.copy(); // The input section are our roots, so we can import that wholesale

        // Connect all the input vertices out to the queue
        QueueVertex tempQueue = new QueueVertex();

        tempGraph = tempGraph.chain(tempQueue);

        // Now we connect the queue to the root of the filter section
        tempGraph = tempGraph.chain(filterSection);

        // Connect the filter section to the filter end vertex to separate from the output section
        tempGraph = tempGraph.chain(new SeparatorVertex("filter_to_output"));

        // Finally, connect the filter out node to all the outputs
        this.graph = tempGraph.chain(outputSection);

        this.queue = selectQueueVertex(this.graph, tempQueue);

        this.graph.validate();

        if (this.getOriginalSource() != null && !this.getOriginalSource().matches("^\\s+$")) {
            uniqueHash = Util.digest(this.getOriginalSource());
        } else {
            uniqueHash = this.graph.uniqueHash();
        }
    }

    public String getOriginalSource() {
        return this.originalSource;
    }

    public List<Vertex> getPostQueue() {
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
    public String uniqueHash() {
        return this.uniqueHash;
    }

    private static QueueVertex selectQueueVertex(final Graph graph, final QueueVertex tempQueue) {
        try {
            return (QueueVertex) graph.getVertexById(tempQueue.getId());
        } catch(NoSuchElementException e) {
            // it's a pipeline without a queue
            return tempQueue;
        }
    }
}
