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


package org.logstash.config.ir.graph;

import org.logstash.common.Util;
import org.logstash.config.ir.InvalidIRException;

public class PlainEdge extends Edge {
    public static class PlainEdgeFactory extends Edge.EdgeFactory {
        @Override
        public PlainEdge make(Vertex from, Vertex to) throws InvalidIRException {
           return new PlainEdge(from, to);
        }
    }

    public static final PlainEdgeFactory factory = new PlainEdgeFactory();

    @Override
    public String individualHashSource() {
        return this.getClass().getCanonicalName();
    }

    @Override
    public String getId() {
        return Util.digest(this.getFrom().getId() + "->" + this.getTo().getId());
    }

    public PlainEdge(Vertex from, Vertex to) throws InvalidIRException {
        super(from, to);
    }

    @Override
    public PlainEdge copy(Vertex from, Vertex to) throws InvalidIRException {
        return new PlainEdge(from, to);
    }
}
