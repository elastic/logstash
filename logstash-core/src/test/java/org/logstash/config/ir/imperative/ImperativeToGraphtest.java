package org.logstash.config.ir.imperative;

import org.junit.Test;
import org.logstash.config.ir.InvalidIRException;
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
        Graph g =  iComposeSequence(iPlugin(FILTER, "json"), iPlugin(FILTER, "stuff")).toGraph();
        Graph expected = graph().threadVertices(gPlugin(FILTER, "json"), gPlugin(FILTER, "stuff"));

        assertGraphEquals(g, expected);
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

        Graph expected = graph().threadVertices(p1,p2,testIf)
            .threadVertices(true, testIf, p3)
            .threadVertices(false, testIf, p4)
            .threadVertices(p4, p5);

        //PluginVertex p6 = gPlugin(FILTER, "p6");
        //expected.threadVertices(p5,p6);

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

        Graph expected = graph()
                .threadVertices(p1, if1)
                .threadVertices(true, if1, if2)
                .threadVertices(false, if1, if4)
                .threadVertices(true, if2, if3)
                .threadVertices(false, if2, p2)
                .threadVertices(p2, if3)
                .threadVertices(true, if3, p3)
                .threadVertices(false, if3, terminal)
                .threadVertices(p3, terminal)
                .threadVertices(true, if4, p4)
                .threadVertices(false, if4, p5)
                .threadVertices(p4, p5)
                .threadVertices(p5, terminal);

        assertGraphEquals(generated, expected);

    }
}
