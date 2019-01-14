package org.logstash.config.ir.imperative;

import org.junit.Test;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.config.ir.BaseSourceComponent;
import org.logstash.config.ir.InvalidIRException;

import static org.logstash.config.ir.DSL.*;
import static org.logstash.config.ir.IRHelpers.assertSyntaxEquals;
import static org.logstash.config.ir.PluginDefinition.Type.*;
import static org.logstash.config.ir.IRHelpers.randMeta;

/**
 * Created by andrewvc on 9/13/16.
 */
public class DSLTest {
    @Test
    public void testDSLOnePluginEquality() throws IncompleteSourceWithMetadataException {
        assertSyntaxEquals(iPlugin(randMeta(), FILTER, "foo"), iPlugin(randMeta(), FILTER, "foo"));
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
        assertSyntaxEquals(iPlugin(randMeta(), FILTER, "grok"), iComposeSequence(iPlugin(randMeta(), FILTER, "grok")));
    }

    @Test
    public void testComposeMulti() throws InvalidIRException {
        Statement composed = iComposeSequence(iPlugin(randMeta(), FILTER, "grok"), iPlugin(randMeta(), FILTER, "foo"));
        assertSyntaxEquals(iComposeSequence(iPlugin(randMeta(), FILTER, "grok"), iPlugin(randMeta(), FILTER, "foo")), composed);
}


    public BaseSourceComponent composedPlugins() throws InvalidIRException {
        return iComposeSequence(iPlugin(randMeta(), FILTER, "json"), iPlugin(randMeta(), FILTER, "stuff"));
    }

    public BaseSourceComponent complexExpression() throws InvalidIRException {
        return iComposeSequence(
                iPlugin(randMeta(), FILTER, "grok"),
                iPlugin(randMeta(), FILTER, "kv"),
                iIf(randMeta(), eAnd(eTruthy(eValue(5l)), eTruthy(eValue(null))),
                        iPlugin(randMeta(), FILTER, "grok"),
                        iComposeSequence(iPlugin(randMeta(), FILTER, "json"), iPlugin(randMeta(), FILTER, "stuff"))
                )
        );
    }


}
