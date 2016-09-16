package org.logstash.config.ir.imperative;

import org.hamcrest.MatcherAssert;
import org.junit.Test;
import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.SourceMetadata;

import java.util.ArrayList;

import static org.logstash.config.ir.DSL.*;


/**
 * Created by andrewvc on 9/13/16.
 */
public class DSLTest {
    @Test
    public void testDSLOnePluginEquality() {
        assertSyntaxEquals(iPlugin("foo"), iPlugin("foo"));
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
        assertSyntaxEquals(iPlugin("grok"), iCompose(iPlugin("grok")));
    }

    @Test
    public void testComposeMulti() throws InvalidIRException {
        ArrayList<Statement> pluginList = new ArrayList<Statement>();
        pluginList.add(iPlugin("grok"));
        pluginList.add(iPlugin("foo"));
        ComposedStatement composed = new ComposedStatement(new SourceMetadata(), pluginList);
        assertSyntaxEquals(iCompose(iPlugin("grok"), iPlugin("foo")), composed);
    }


    public SourceComponent composedPlugins() throws InvalidIRException {
        return iCompose(iPlugin("json"), iPlugin("stuff"));
    }

    public SourceComponent complexExpression() throws InvalidIRException {
        return iCompose(
                iPlugin("grok"),
                iPlugin("kv"),
                iIf(eAnd(eNotNull(eValue(5l)), eNotNull(null)),
                        iPlugin("grok"),
                        iCompose(iPlugin("json"), iPlugin("stuff"))
                )
        );
    }

    public void assertSyntaxEquals(SourceComponent left, SourceComponent right) {
        String message = String.format("Expected '%s' to equal '%s'", left, right);
        MatcherAssert.assertThat(message, left.sourceComponentEquals(right));
    }
}
