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


package org.logstash.config.ir.graph.algorithms;

import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.graph.Edge;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.Vertex;

public class GraphDiff {
    public static DiffResult diff(Graph left, Graph right) {
        List<Edge> removedEdges = left.edges().filter(e -> !right.hasEquivalentEdge(e)).collect(Collectors.toList());
        List<Vertex> removedVertices = left.vertices().filter(v -> !right.hasEquivalentVertex(v)).collect(Collectors.toList());
        List<Edge> addedEdges = right.edges().filter(e -> !left.hasEquivalentEdge(e)).collect(Collectors.toList());
        List<Vertex> addedVertices = right.vertices().filter(v -> !left.hasEquivalentVertex(v)).collect(Collectors.toList());
        return new DiffResult(removedEdges, addedEdges, removedVertices, addedVertices);
    }

    public static class DiffResult {
        private final List<Vertex> removedVertices;
        private final List<Vertex> addedVertices;
        private final Collection<Edge> removedEdges;
        private final Collection<Edge> addedEdges;

        public Collection<Edge> getRemovedEdges() {
            return removedEdges;
        }

        public Collection<Edge> getAddedEdges() {
            return addedEdges;
        }

        public Collection<Vertex> getRemovedVertices() {
            return removedVertices;
        }

        public Collection<Vertex> getAddedVertices() {
            return addedVertices;
        }

        public DiffResult(Collection<Edge> removedEdges, Collection<Edge> addedEdges, List<Vertex> removedVertices, List<Vertex> addedVertices) {
            this.removedEdges = removedEdges;
            this.addedEdges = addedEdges;
            this.removedVertices = removedVertices;
            this.addedVertices = addedVertices;
        }

        public String summary() {
            String template = "(-%d,+%d Edges | -%d,+%d Vertices)";
            return String.format(template, removedEdges.size(), addedEdges.size(), removedVertices.size(), addedVertices.size());
        }

        public boolean hasSameEdges() {
            return addedEdges.isEmpty() && removedEdges.isEmpty();
        }

        public boolean hasSameVertices() {
            return addedVertices.isEmpty() && removedVertices.isEmpty();
        }

        public boolean isIdentical() {
            return hasSameEdges() && hasSameVertices();
        }

        public String toString() {
            if (isIdentical()) return "Identical Graphs";

            StringBuilder output = new StringBuilder();
            output.append(this.summary());

            if (!hasSameEdges()) {
                output.append("\n");
                output.append(detailedDiffFor("Edges", removedEdges, addedEdges));
            }
            if (!hasSameVertices()) {
                output.append("\n");
                output.append(detailedDiffFor("Vertices", removedVertices, addedVertices));
            }
            output.append("\n");

            return output.toString();
        }

        private static String detailedDiffFor(final String name,
            final Collection<? extends SourceComponent> removed,
            final Collection<? extends SourceComponent> added) {
            return name + " GraphDiff: \n--------------------------\n" +
                Stream.concat(
                    removed.stream().map(c -> '-' + c.toString()),
                    added.stream().map(c -> '+' + c.toString())
                ).map(Object::toString).collect(Collectors.joining("\n")) +
                "\n--------------------------";
        }
    }
}
