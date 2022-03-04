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


package org.logstash.config.ir.imperative;

import org.junit.Test;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.logstash.common.EnvironmentVariableProvider;
import org.logstash.config.ir.DSL;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.PluginDefinition;
import org.logstash.config.ir.expression.BooleanExpression;
import org.logstash.config.ir.graph.*;
import org.logstash.plugins.ConfigVariableExpander;

import static org.logstash.config.ir.IRHelpers.*;

public class IfStatementTest {

    @Test
    public void testEmptyIf() throws InvalidIRException {
        ConfigVariableExpander cve = ConfigVariableExpander.withoutSecret(EnvironmentVariableProvider.defaultProvider());
        Statement trueStatement = new NoopStatement(randMeta());
        Statement falseStatement = new NoopStatement(randMeta());
        IfStatement ifStatement = new IfStatement(
                randMeta(),
                createTestExpression(),
                trueStatement,
                falseStatement
        );

        Graph ifStatementGraph = ifStatement.toGraph(cve);
        assertTrue(ifStatementGraph.isEmpty());
    }

    @Test
    public void testIfWithOneTrueStatement() throws InvalidIRException {
        ConfigVariableExpander cve = ConfigVariableExpander.withoutSecret(EnvironmentVariableProvider.defaultProvider());
        PluginDefinition pluginDef = testPluginDefinition();
        Statement trueStatement = new PluginStatement(randMeta(), pluginDef);
        Statement falseStatement = new NoopStatement(randMeta());
        BooleanExpression ifExpression = createTestExpression();
        IfStatement ifStatement = new IfStatement(
                randMeta(),
                ifExpression,
                trueStatement,
                falseStatement
        );

        Graph ifStatementGraph = ifStatement.toGraph(cve);
        assertFalse(ifStatementGraph.isEmpty());
        
        Graph expected = new Graph();
        IfVertex expectedIf = DSL.gIf(randMeta(), ifExpression);
        expected.addVertex(expectedIf);
        PluginVertex expectedT = DSL.gPlugin(randMeta(), pluginDef);
        expected.chainVertices(true, expectedIf, expectedT);

        assertSyntaxEquals(expected, ifStatementGraph);
    }


    @Test
    public void testIfWithOneFalseStatement() throws InvalidIRException {
        ConfigVariableExpander cve = ConfigVariableExpander.withoutSecret(EnvironmentVariableProvider.defaultProvider());
        PluginDefinition pluginDef = testPluginDefinition();
        Statement trueStatement = new NoopStatement(randMeta());
        Statement falseStatement = new PluginStatement(randMeta(), pluginDef);
        BooleanExpression ifExpression = createTestExpression();
        IfStatement ifStatement = new IfStatement(
                randMeta(),
                createTestExpression(),
                trueStatement,
                falseStatement
        );

        Graph ifStatementGraph = ifStatement.toGraph(cve);
        assertFalse(ifStatementGraph.isEmpty());

        Graph expected = new Graph();
        IfVertex expectedIf = DSL.gIf(randMeta(), ifExpression);
        expected.addVertex(expectedIf);

        PluginVertex expectedF = DSL.gPlugin(randMeta(), pluginDef);
        expected.chainVertices(false, expectedIf, expectedF);

        assertSyntaxEquals(expected, ifStatementGraph);
    }

    @Test
    public void testIfWithOneTrueOneFalseStatement() throws InvalidIRException {
        ConfigVariableExpander cve = ConfigVariableExpander.withoutSecret(EnvironmentVariableProvider.defaultProvider());
        PluginDefinition pluginDef = testPluginDefinition();
        Statement trueStatement = new PluginStatement(randMeta(), pluginDef);
        Statement falseStatement = new PluginStatement(randMeta(), pluginDef);
        BooleanExpression ifExpression = createTestExpression();
        IfStatement ifStatement = new IfStatement(
                randMeta(),
                createTestExpression(),
                trueStatement,
                falseStatement
        );

        Graph ifStatementGraph = ifStatement.toGraph(cve);
        assertFalse(ifStatementGraph.isEmpty());

        Graph expected = new Graph();
        IfVertex expectedIf = DSL.gIf(randMeta(), ifExpression);
        expected.addVertex(expectedIf);

        PluginVertex expectedT = DSL.gPlugin(randMeta(), pluginDef);
        expected.chainVertices(true, expectedIf, expectedT);

        PluginVertex expectedF = DSL.gPlugin(randMeta(), pluginDef);
        expected.chainVertices(false, expectedIf, expectedF);

        assertSyntaxEquals(expected, ifStatementGraph);
    }
}
