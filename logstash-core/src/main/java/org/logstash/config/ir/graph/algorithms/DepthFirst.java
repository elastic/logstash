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

import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.Vertex;

import java.util.*;
import java.util.stream.Stream;
import java.util.stream.StreamSupport;

public class DepthFirst {
    public static Stream<Vertex> depthFirst(Graph g) {
        return depthFirst(g.getRoots());
    }

    public static Stream<Vertex> reverseDepthFirst(Graph g) {
        return reverseDepthFirst(g.getLeaves());
    }

    public static Stream<Vertex> depthFirst(Vertex v) {
        return depthFirst(Collections.singleton(v));
    }

    public static Stream<Vertex> reverseDepthFirst(Vertex v) {
        return reverseDepthFirst(Collections.singleton(v));
    }

    public static Stream<Vertex> depthFirst(Collection<Vertex> v) {
        return streamify(new Traversal(v, false));
    }

    public static Stream<Vertex> reverseDepthFirst(Collection<Vertex> v) {
        return streamify(new Traversal(v, true));
    }

    private static Stream<Vertex> streamify(Traversal t) {
         return StreamSupport.stream(Spliterators.spliteratorUnknownSize(t, Spliterator.DISTINCT),false);
    }

    public static class Traversal implements Iterator<Vertex> {
        private final Set<Vertex> visited = new HashSet<>();
        private final Deque<Vertex> pending;
        private final boolean reverse;

        Traversal(Collection<Vertex> initialVertices, boolean reverse) {
            this.reverse = reverse;
            this.pending = new ArrayDeque<>(initialVertices);
        }

        @Override
        public boolean hasNext() {
            return !pending.isEmpty();
        }

        @Override
        public Vertex next() {
            Vertex current = pending.removeFirst();
            this.visited.add(current);

            Stream<Vertex> next = reverse ? current.incomingVertices() : current.outgoingVertices();
            next.forEach(v -> {
                if (!visited.contains(v)) {
                    this.pending.add(v);
                }
            });
            return current;
        }
    }
}
