package org.logstash.config.ir;

import org.junit.Test;
import org.logstash.common.Util;
import org.logstash.config.ir.graph.Graph;

import java.nio.channels.Pipe;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThat;
import static org.junit.Assert.assertTrue;
import static org.logstash.config.ir.DSL.*;
import static org.logstash.config.ir.PluginDefinition.Type.*;

/**
 * Created by andrewvc on 9/20/16.
 */
public class PipelineIRTest {
    public Graph makeInputSection() throws InvalidIRException {
        return iComposeParallel(iPlugin(INPUT, "generator"), iPlugin(INPUT, "stdin")).toGraph();
    }

    public Graph makeFilterSection() throws InvalidIRException {
        return iIf(eEq(eEventValue("[foo]"), eEventValue("[bar]")),
                                    iPlugin(FILTER, "grok"),
                                    iPlugin(FILTER, "kv")).toGraph();
    }

    public Graph makeOutputSection() throws InvalidIRException {
        return iIf(eGt(eEventValue("[baz]"), eValue(1000)),
                                    iComposeParallel(
                                            iPlugin(OUTPUT, "s3"),
                                            iPlugin(OUTPUT, "elasticsearch")),
                                    iPlugin(OUTPUT, "stdout")).toGraph();
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
