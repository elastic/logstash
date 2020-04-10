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
import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.InvalidIRException;

public final class BooleanEdge extends Edge {
    public static class BooleanEdgeFactory extends EdgeFactory {
        public Boolean getEdgeType() {
            return edgeType;
        }

        private final Boolean edgeType;

        public BooleanEdgeFactory(Boolean edgeType) {
            this.edgeType = edgeType;
        }

        public BooleanEdge make(Vertex in, Vertex out) throws InvalidIRException {
            return new BooleanEdge(edgeType, in, out);
        }

        @Override
        public int hashCode() {
            return this.edgeType.hashCode();
        }

        public boolean equals(Object other) {
            if (other == null) return false;
            if (other instanceof BooleanEdgeFactory) {
               return ((BooleanEdgeFactory) other).getEdgeType().equals(edgeType);
            }
            return false;
        }

        public String toString() {
            return "BooleanEdge.BooleanEdgeFactory[" + edgeType + "]";
        }
    }
    public static final BooleanEdge.BooleanEdgeFactory trueFactory = new BooleanEdge.BooleanEdgeFactory(true);
    public static final BooleanEdge.BooleanEdgeFactory falseFactory = new BooleanEdge.BooleanEdgeFactory(false);

    private final Boolean edgeType;

    public Boolean getEdgeType() {
        return edgeType;
    }

    public BooleanEdge(Boolean edgeType, Vertex outVertex, Vertex inVertex) throws InvalidIRException {
        super(outVertex, inVertex);
        this.edgeType = edgeType;
    }

    @Override
    public String individualHashSource() {
        return this.getClass().getCanonicalName() + "|" + this.getEdgeType() + "|";
    }

    @Override
    public String getId() {
        return Util.digest(this.getFrom().getId() + "[" + this.getEdgeType() + "]->" + this.getTo().getId());
    }

    public String toString() {
        return getFrom() + " -|" + this.edgeType + "|-> " + getTo();
    }

    @Override
    public boolean sourceComponentEquals(SourceComponent sourceComponent) {
        if (sourceComponent == null) return false;
        if (sourceComponent == this) return true;
        if (sourceComponent instanceof BooleanEdge) {
            BooleanEdge otherE = (BooleanEdge) sourceComponent;

            return this.getFrom().sourceComponentEquals(otherE.getFrom()) &&
                    this.getTo().sourceComponentEquals(otherE.getTo()) &&
                    this.getEdgeType().equals(otherE.getEdgeType());
        }
        return false;
    }

    @Override
    public BooleanEdge copy(Vertex from, Vertex to) throws InvalidIRException {
        return new BooleanEdge(this.edgeType, from, to);
    }

}
