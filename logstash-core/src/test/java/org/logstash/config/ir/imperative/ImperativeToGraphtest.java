package org.logstash.config.ir.imperative;

import org.junit.Test;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.Pipeline;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.IfVertex;
import org.logstash.config.ir.graph.PluginVertex;

import static org.logstash.config.ir.DSL.*;
import static org.logstash.config.ir.IRHelpers.assertGraphEquals;
import static org.logstash.config.ir.PluginDefinition.Type.*;

/**
 * Created by andrewvc on 9/15/16.
 */
public class ImperativeToGraphtest {

    @Test
    public void convertSimpleExpression() throws InvalidIRException {
        Graph imperative =  iComposeSequence(iPlugin(FILTER, "json"), iPlugin(FILTER, "stuff")).toGraph();
        Graph regular = Graph.empty();
        regular.threadVertices(gPlugin(FILTER, "json"), gPlugin(FILTER, "stuff"));

        assertGraphEquals(imperative, regular);
    }

    @Test
    public void testIdsDontAffectSourceComponentEquality() throws InvalidIRException {
        Graph imperative =  iComposeSequence(iPlugin(FILTER, "json", "oneid"), iPlugin(FILTER, "stuff", "anotherid")).toGraph();
        Graph regular = Graph.empty();
        regular.threadVertices(gPlugin(FILTER, "json", "someotherid"), gPlugin(FILTER, "stuff", "graphid"));

        assertGraphEquals(imperative, regular);
    }

    @Test
    public void convertComplexExpression() throws InvalidIRException {
        Graph generated = iComposeSequence(
                iPlugin(FILTER, "p1"),
                iPlugin(FILTER, "p2"),
                iIf(eAnd(eTruthy(eValue(5l)), eTruthy(eValue(null))),
                        iPlugin(FILTER, "p3"),
                        iComposeSequence(iPlugin(FILTER, "p4"), iPlugin(FILTER, "p5"))
                )
        ).toGraph();

        PluginVertex p1 = gPlugin(FILTER, "p1");
        PluginVertex p2 = gPlugin(FILTER, "p2");
        PluginVertex p3 = gPlugin(FILTER, "p3");
        PluginVertex p4 = gPlugin(FILTER, "p4");
        PluginVertex p5 = gPlugin(FILTER, "p5");
        IfVertex testIf = gIf(eAnd(eTruthy(eValue(5l)), eTruthy(eValue(null))));

        Graph expected = Graph.empty();
        expected.threadVertices(p1,p2,testIf);
        expected.threadVertices(true, testIf, p3);
        expected.threadVertices(false, testIf, p4);
        expected.threadVertices(p4, p5);

        assertGraphEquals(expected, generated);
    }

    // This test has an imperative grammar with nested ifs and dangling
    // partial leaves. This makes sure they all wire-up right
    @Test
    public void deepDanglingPartialLeaves() throws InvalidIRException {
         Graph generated = iComposeSequence(
                 iPlugin(FILTER, "p0"),
                 iIf(eTruthy(eValue(1)),
                         iPlugin(FILTER, "p1"),
                         iIf(eTruthy(eValue(3)),
                             iPlugin(FILTER, "p5"))
                 ),
                 iIf(eTruthy(eValue(2)),
                         iPlugin(FILTER, "p3"),
                         iPlugin(FILTER, "p4")
                 ),
                 iPlugin(FILTER, "pLast")

         ).toGraph();

        IfVertex if1 = gIf(eTruthy(eValue(1)));
        IfVertex if2 = gIf(eTruthy(eValue(2)));
        IfVertex if3 = gIf(eTruthy(eValue(3)));
        PluginVertex p0 = gPlugin(FILTER, "p0");
        PluginVertex p1 = gPlugin(FILTER, "p1");
        PluginVertex p2 = gPlugin(FILTER, "p2");
        PluginVertex p3 = gPlugin(FILTER, "p3");
        PluginVertex p4 = gPlugin(FILTER, "p4");
        PluginVertex p5 = gPlugin(FILTER, "p5");
        PluginVertex pLast = gPlugin(FILTER, "pLast");

        Graph expected = Graph.empty();
        expected.threadVertices(p0, if1);
        expected.threadVertices(true, if1, p1);
        expected.threadVertices(false, if1, if3);
        expected.threadVertices(true, if3, p5);
        expected.threadVertices(false, if3, if2);
        expected.threadVertices(p5, if2);
        expected.threadVertices(p1, if2);
        expected.threadVertices(true, if2, p3);
        expected.threadVertices(false, if2, p4);
        expected.threadVertices(p3, pLast);
        expected.threadVertices(p4,pLast);

        assertGraphEquals(generated, expected);
    }

    // This is a good test for what the filter block will do, where there
    // will be a  composed set of ifs potentially, all of which must terminate at a
    // single node
    @Test
    public void convertComplexExpressionWithTerminal() throws InvalidIRException {
        Graph generated = iComposeSequence(
            iPlugin(FILTER, "p1"),
            iIf(eTruthy(eValue(1)),
                iComposeSequence(
                    iIf(eTruthy(eValue(2)), noop(), iPlugin(FILTER, "p2")),
                    iIf(eTruthy(eValue(3)), iPlugin(FILTER, "p3"), noop())
                ),
                iComposeSequence(
                    iIf(eTruthy(eValue(4)), iPlugin(FILTER, "p4")),
                    iPlugin(FILTER, "p5")
                )
            ),
            iPlugin(FILTER, "terminal")
        ).toGraph();

        PluginVertex p1 = gPlugin(FILTER,"p1");
        PluginVertex p2 = gPlugin(FILTER, "p2");
        PluginVertex p3 = gPlugin(FILTER, "p3");
        PluginVertex p4 = gPlugin(FILTER, "p4");
        PluginVertex p5 = gPlugin(FILTER, "p5");
        PluginVertex terminal = gPlugin(FILTER, "terminal");

        IfVertex if1 = gIf(eTruthy(eValue(1)));
        IfVertex if2 = gIf(eTruthy(eValue(2)));
        IfVertex if3 = gIf(eTruthy(eValue(3)));
        IfVertex if4 = gIf(eTruthy(eValue(4)));

        Graph expected = Graph.empty();
        expected.threadVertices(p1, if1);
        expected.threadVertices(true, if1, if2);
        expected.threadVertices(false, if1, if4);
        expected.threadVertices(true, if2, if3);
        expected.threadVertices(false, if2, p2);
        expected.threadVertices(p2, if3);
        expected.threadVertices(true, if3, p3);
        expected.threadVertices(false, if3, terminal);
        expected.threadVertices(p3, terminal);
        expected.threadVertices(true, if4, p4);
        expected.threadVertices(false, if4, p5);
        expected.threadVertices(p4, p5);
        expected.threadVertices(p5, terminal);

        assertGraphEquals(generated, expected);

    }
}
