package org.logstash.config.ir.imperative;

import org.junit.Test;
import org.logstash.config.ir.BaseSourceComponent;
import org.logstash.config.ir.InvalidIRException;

import static org.logstash.config.ir.DSL.*;
import static org.logstash.config.ir.IRHelpers.assertSyntaxEquals;
import static org.logstash.config.ir.PluginDefinition.Type.*;

/**
 * Created by andrewvc on 9/13/16.
 */
public class DSLTest {
    @Test
    public void testDSLOnePluginEquality() {
        assertSyntaxEquals(iPlugin(FILTER, "foo"), iPlugin(FILTER, "foo"));
    }

    @Test
    public void testComposedPluginEquality() throws InvalidIRException {
        assertSyntaxEquals(composedPlugins(), composedPlugins());
    }

    @Test
    public void testDSLComplexEquality() throws InvalidIRException {
        assertSyntaxEquals(complexExpression(), complexExpression());
    }

    @Test
    public void testComposeSingle() throws InvalidIRException {
        assertSyntaxEquals(iPlugin(FILTER, "grok"), iComposeSequence(iPlugin(FILTER, "grok")));
    }

    @Test
    public void testComposeMulti() throws InvalidIRException {
        Statement composed = iComposeSequence(iPlugin(FILTER, "grok"), iPlugin(FILTER, "foo"));
        assertSyntaxEquals(iComposeSequence(iPlugin(FILTER, "grok"), iPlugin(FILTER, "foo")), composed);
}


    public BaseSourceComponent composedPlugins() throws InvalidIRException {
        return iComposeSequence(iPlugin(FILTER, "json"), iPlugin(FILTER, "stuff"));
    }

    public BaseSourceComponent complexExpression() throws InvalidIRException {
        return iComposeSequence(
                iPlugin(FILTER, "grok"),
                iPlugin(FILTER, "kv"),
                iIf(eAnd(eTruthy(eValue(5l)), eTruthy(eValue(null))),
                        iPlugin(FILTER, "grok"),
                        iComposeSequence(iPlugin(FILTER, "json"), iPlugin(FILTER, "stuff"))
                )
        );
    }


}
