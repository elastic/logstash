package org.logstash.config.ir;

import org.junit.Test;
import org.logstash.common.Util;
import org.logstash.config.ir.graph.Graph;

import static org.junit.Assert.assertEquals;
import static org.logstash.config.ir.DSL.*;
import static org.logstash.config.ir.PluginDefinition.Type.*;
import static org.logstash.config.ir.IRHelpers.randMeta;

/**
 * Created by andrewvc on 9/20/16.
 */
public class PipelineIRTest {
    public Graph makeInputSection() throws InvalidIRException {
        return iComposeParallel(iPlugin(randMeta(), INPUT, "generator"), iPlugin(randMeta(), INPUT, "stdin")).toGraph();
    }

    public Graph makeFilterSection() throws InvalidIRException {
        return iIf(randMeta(), eEq(eEventValue("[foo]"), eEventValue("[bar]")),
                                    iPlugin(randMeta(), FILTER, "grok"),
                                    iPlugin(randMeta(), FILTER, "kv")).toGraph();
    }

    public Graph makeOutputSection() throws InvalidIRException {
        return iIf(randMeta(), eGt(eEventValue("[baz]"), eValue(1000)),
                                    iComposeParallel(
                                            iPlugin(randMeta(), OUTPUT, "s3"),
                                            iPlugin(randMeta(), OUTPUT, "elasticsearch")),
                                    iPlugin(randMeta(), OUTPUT, "stdout")).toGraph();
    }

    @Test
    public void testPipelineCreation() throws InvalidIRException {
        PipelineIR pipelineIR = new PipelineIR(makeInputSection(), makeFilterSection(), makeOutputSection());
        assertEquals(2, pipelineIR.getInputPluginVertices().size());
        assertEquals(2, pipelineIR.getFilterPluginVertices().size());
        assertEquals(3, pipelineIR.getOutputPluginVertices().size());
    }

    @Test
    public void hashingWithoutOriginalSource() throws InvalidIRException {
        PipelineIR pipelineIR = new PipelineIR(makeInputSection(), makeFilterSection(), makeOutputSection());
        assertEquals(pipelineIR.uniqueHash(), pipelineIR.getGraph().uniqueHash());
    }

    @Test
    public void hashingWithOriginalSource() throws InvalidIRException {
        String source = "input { stdin {} } output { stdout {} }";
        PipelineIR pipelineIR = new PipelineIR(makeInputSection(), makeFilterSection(), makeOutputSection(), source);
        assertEquals(pipelineIR.uniqueHash(), Util.digest(source));
    }
}
