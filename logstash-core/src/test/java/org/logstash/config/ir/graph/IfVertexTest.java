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

import org.junit.Test;
import org.logstash.common.ConfigVariableExpanderTest;
import org.logstash.config.ir.DSL;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.expression.BooleanExpression;
import org.logstash.config.ir.expression.ExpressionSubstitution;
import org.logstash.config.ir.expression.binary.Eq;
import org.logstash.plugins.ConfigVariableExpander;

import java.util.Collections;

import static org.hamcrest.CoreMatchers.*;
import static org.junit.Assert.assertThat;
import static org.logstash.config.ir.IRHelpers.*;

public class IfVertexTest {
    @Test
    public void testIfVertexCreation() throws InvalidIRException {
        testIfVertex();
    }

    @Test(expected = Vertex.InvalidEdgeTypeException.class)
    public void testDoesNotAcceptNonBooleanEdges() throws InvalidIRException {
        Graph graph = Graph.empty();
        IfVertex ifV = testIfVertex();
        Vertex otherV = createTestVertex();
        graph.chainVertices(PlainEdge.factory, ifV, otherV);
    }

    @Test
    public void testEdgeTypeHandling() throws InvalidIRException {
        Graph graph = Graph.empty();
        IfVertex ifV = testIfVertex();
        graph.addVertex(ifV);
        Vertex trueV = createTestVertex();
        graph.addVertex(trueV);

        assertThat(ifV.hasEdgeType(true), is(false));
        assertThat(ifV.hasEdgeType(false), is(false));
        assertThat(ifV.getUnusedOutgoingEdgeFactories().size(), is(2));

        graph.chainVertices(BooleanEdge.trueFactory, ifV, trueV);

        assertThat(ifV.hasEdgeType(true), is(true));
        assertThat(ifV.hasEdgeType(false), is(false));
        assertThat(ifV.getUnusedOutgoingEdgeFactories().size(), is(1));
        assertThat(
                ifV.getUnusedOutgoingEdgeFactories().stream().findFirst().get(),
                is(BooleanEdge.falseFactory)
        );

        Vertex falseV = createTestVertex();
        graph.chainVertices(BooleanEdge.falseFactory, ifV, falseV);

        assertThat(ifV.hasEdgeType(false), is(true));
        assertThat(ifV.getUnusedOutgoingEdgeFactories().isEmpty(), is(true));


        BooleanEdge trueEdge = ifV.outgoingBooleanEdgesByType(true).findAny().get();
        BooleanEdge falseEdge = ifV.outgoingBooleanEdgesByType(false).findAny().get();
        assertThat(trueEdge.getEdgeType(), is(true));
        assertThat(falseEdge.getEdgeType(), is(false));
    }

    public IfVertex testIfVertex() throws InvalidIRException {
        return new IfVertex(randMeta(), createTestExpression());
    }

    @Test
    public void testIfVertexWithSecretsIsntLeaked() throws InvalidIRException {
        BooleanExpression booleanExpression = DSL.eEq(DSL.eEventValue("password"), DSL.eValue("${secret_key}"));

        ConfigVariableExpander cve = ConfigVariableExpanderTest.getFakeCve(
                Collections.singletonMap("secret_key", "s3cr3t"), Collections.emptyMap());

        IfVertex ifVertex = new IfVertex(randMeta(),
                (BooleanExpression) ExpressionSubstitution.substituteBoolExpression(cve, booleanExpression));

        // Exercise
        String output = ifVertex.toString();

        // Verify
        assertThat(output, not(containsString("s3cr3t")));
    }

}
