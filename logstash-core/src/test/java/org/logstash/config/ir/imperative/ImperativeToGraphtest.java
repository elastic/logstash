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
import org.logstash.common.EnvironmentVariableProvider;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.IfVertex;
import org.logstash.config.ir.graph.PluginVertex;
import org.logstash.plugins.ConfigVariableExpander;

import static org.logstash.config.ir.DSL.*;
import static org.logstash.config.ir.IRHelpers.assertSyntaxEquals;
import static org.logstash.config.ir.IRHelpers.randMeta;
import static org.logstash.config.ir.PluginDefinition.Type.*;

public class ImperativeToGraphtest {

    @Test
    public void convertSimpleExpression() throws InvalidIRException {
        ConfigVariableExpander cve = ConfigVariableExpander.withoutSecret(EnvironmentVariableProvider.defaultProvider());
        Graph imperative =  iComposeSequence(randMeta(), iPlugin(randMeta(), FILTER, "json"), iPlugin(randMeta(), FILTER, "stuff")).toGraph(cve);
        imperative.validate(); // Verify this is a valid graph

        Graph regular = Graph.empty();
        regular.chainVertices(gPlugin(randMeta(), FILTER, "json"), gPlugin(randMeta(), FILTER, "stuff"));

        assertSyntaxEquals(imperative, regular);
    }

    @Test
    public void testIdsDontAffectSourceComponentEquality() throws InvalidIRException {
        ConfigVariableExpander cve = ConfigVariableExpander.withoutSecret(EnvironmentVariableProvider.defaultProvider());
        Graph imperative =  iComposeSequence(
                iPlugin(randMeta(), FILTER, "json", "oneid"),
                iPlugin(randMeta(), FILTER, "stuff", "anotherid")
        ).toGraph(cve);
        imperative.validate(); // Verify this is a valid graph

        Graph regular = Graph.empty();
        regular.chainVertices(
                gPlugin(randMeta(), FILTER, "json", "someotherid"),
                gPlugin(randMeta(), FILTER, "stuff", "graphid")
        );

        assertSyntaxEquals(imperative, regular);
    }

    @Test
    public void convertComplexExpression() throws InvalidIRException {
        ConfigVariableExpander cve = ConfigVariableExpander.withoutSecret(EnvironmentVariableProvider.defaultProvider());
        Graph imperative = iComposeSequence(
                iPlugin(randMeta(), FILTER, "p1"),
                iPlugin(randMeta(), FILTER, "p2"),
                iIf(randMeta(), eAnd(eTruthy(eValue(5l)), eTruthy(eValue(null))),
                        iPlugin(randMeta(), FILTER, "p3"),
                        iComposeSequence(iPlugin(randMeta(), FILTER, "p4"), iPlugin(randMeta(), FILTER, "p5"))
                )
        ).toGraph(cve);
        imperative.validate(); // Verify this is a valid graph

        PluginVertex p1 = gPlugin(randMeta(), FILTER, "p1");
        PluginVertex p2 = gPlugin(randMeta(), FILTER, "p2");
        PluginVertex p3 = gPlugin(randMeta(), FILTER, "p3");
        PluginVertex p4 = gPlugin(randMeta(), FILTER, "p4");
        PluginVertex p5 = gPlugin(randMeta(), FILTER, "p5");
        IfVertex testIf = gIf(randMeta(), eAnd(eTruthy(eValue(5l)), eTruthy(eValue(null))));

        Graph expected = Graph.empty();
        expected.chainVertices(p1,p2,testIf);
        expected.chainVertices(true, testIf, p3);
        expected.chainVertices(false, testIf, p4);
        expected.chainVertices(p4, p5);

        assertSyntaxEquals(expected, imperative);
    }

    // This test has an imperative grammar with nested ifs and dangling
    // partial leaves. This makes sure they all wire-up right
    @Test
    public void deepDanglingPartialLeaves() throws InvalidIRException {
        ConfigVariableExpander cve = ConfigVariableExpander.withoutSecret(EnvironmentVariableProvider.defaultProvider());
        Graph imperative = iComposeSequence(
                 iPlugin(randMeta(), FILTER, "p0"),
                 iIf(randMeta(), eTruthy(eValue(1)),
                         iPlugin(randMeta(), FILTER, "p1"),
                         iIf(randMeta(), eTruthy(eValue(3)),
                             iPlugin(randMeta(), FILTER, "p5"))
                 ),
                 iIf(randMeta(), eTruthy(eValue(2)),
                         iPlugin(randMeta(), FILTER, "p3"),
                         iPlugin(randMeta(), FILTER, "p4")
                 ),
                 iPlugin(randMeta(), FILTER, "pLast")

         ).toGraph(cve);
        imperative.validate(); // Verify this is a valid graph

        IfVertex if1 = gIf(randMeta(), eTruthy(eValue(1)));
        IfVertex if2 = gIf(randMeta(), eTruthy(eValue(2)));
        IfVertex if3 = gIf(randMeta(), eTruthy(eValue(3)));
        PluginVertex p0 = gPlugin(randMeta(), FILTER, "p0");
        PluginVertex p1 = gPlugin(randMeta(), FILTER, "p1");
        PluginVertex p2 = gPlugin(randMeta(), FILTER, "p2");
        PluginVertex p3 = gPlugin(randMeta(), FILTER, "p3");
        PluginVertex p4 = gPlugin(randMeta(), FILTER, "p4");
        PluginVertex p5 = gPlugin(randMeta(), FILTER, "p5");
        PluginVertex pLast = gPlugin(randMeta(), FILTER, "pLast");

        Graph expected = Graph.empty();
        expected.chainVertices(p0, if1);
        expected.chainVertices(true, if1, p1);
        expected.chainVertices(false, if1, if3);
        expected.chainVertices(true, if3, p5);
        expected.chainVertices(false, if3, if2);
        expected.chainVertices(p5, if2);
        expected.chainVertices(p1, if2);
        expected.chainVertices(true, if2, p3);
        expected.chainVertices(false, if2, p4);
        expected.chainVertices(p3, pLast);
        expected.chainVertices(p4,pLast);

        assertSyntaxEquals(imperative, expected);
    }

    // This is a good test for what the filter block will do, where there
    // will be a  composed set of ifs potentially, all of which must terminate at a
    // single node
    @Test
    public void convertComplexExpressionWithTerminal() throws InvalidIRException {
        ConfigVariableExpander cve = ConfigVariableExpander.withoutSecret(EnvironmentVariableProvider.defaultProvider());
        Graph imperative = iComposeSequence(
            iPlugin(randMeta(), FILTER, "p1"),
            iIf(randMeta(), eTruthy(eValue(1)),
                iComposeSequence(
                    iIf(randMeta(), eTruthy(eValue(2)), noop(), iPlugin(randMeta(), FILTER, "p2")),
                    iIf(randMeta(), eTruthy(eValue(3)), iPlugin(randMeta(), FILTER, "p3"), noop())
                ),
                iComposeSequence(
                    iIf(randMeta(), eTruthy(eValue(4)), iPlugin(randMeta(), FILTER, "p4")),
                    iPlugin(randMeta(), FILTER, "p5")
                )
            ),
            iPlugin(randMeta(), FILTER, "terminal")
        ).toGraph(cve);
        imperative.validate(); // Verify this is a valid graph

        PluginVertex p1 = gPlugin(randMeta(), FILTER,"p1");
        PluginVertex p2 = gPlugin(randMeta(), FILTER, "p2");
        PluginVertex p3 = gPlugin(randMeta(), FILTER, "p3");
        PluginVertex p4 = gPlugin(randMeta(), FILTER, "p4");
        PluginVertex p5 = gPlugin(randMeta(), FILTER, "p5");
        PluginVertex terminal = gPlugin(randMeta(), FILTER, "terminal");

        IfVertex if1 = gIf(randMeta(), eTruthy(eValue(1)));
        IfVertex if2 = gIf(randMeta(), eTruthy(eValue(2)));
        IfVertex if3 = gIf(randMeta(), eTruthy(eValue(3)));
        IfVertex if4 = gIf(randMeta(), eTruthy(eValue(4)));

        Graph expected = Graph.empty();
        expected.chainVertices(p1, if1);
        expected.chainVertices(true, if1, if2);
        expected.chainVertices(false, if1, if4);
        expected.chainVertices(true, if2, if3);
        expected.chainVertices(false, if2, p2);
        expected.chainVertices(p2, if3);
        expected.chainVertices(true, if3, p3);
        expected.chainVertices(false, if3, terminal);
        expected.chainVertices(p3, terminal);
        expected.chainVertices(true, if4, p4);
        expected.chainVertices(false, if4, p5);
        expected.chainVertices(p4, p5);
        expected.chainVertices(p5, terminal);

        assertSyntaxEquals(imperative, expected);

    }
}
