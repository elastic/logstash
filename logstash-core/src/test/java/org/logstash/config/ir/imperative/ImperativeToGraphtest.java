package org.logstash.config.ir.imperative;

import org.junit.Test;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.graph.Graph;

import static org.logstash.config.ir.DSL.*;
import static org.logstash.config.ir.DSL.eNotNull;
import static org.logstash.config.ir.DSL.eValue;

/**
 * Created by andrewvc on 9/15/16.
 */
public class ImperativeToGraphtest {
    @Test
    public void convertSimpleExpression() throws InvalidIRException {
        Graph g =  iCompose(iPlugin("json"), iPlugin("stuff")).toGraph();
        System.out.println(g);
    }

    @Test
    public void convertComplexExpression() throws InvalidIRException {
        Graph g = iCompose(
                iPlugin("grok"),
                iPlugin("kv"),
                iIf(eAnd(eNotNull(eValue(5l)), eNotNull(null)),
                        iPlugin("grok"),
                        iCompose(iPlugin("json"), iPlugin("stuff"))
                )
        ).toGraph();
        System.out.println(g);
    }
}
