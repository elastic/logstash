package org.logstash.config.ir;

import org.junit.Test;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.pipeline.Pipeline;

import static org.logstash.config.ir.DSL.*;
import static org.logstash.config.ir.PluginDefinition.Type.*;

/**
 * Created by andrewvc on 9/20/16.
 */
public class PipelineTest {
    @Test
    public void testPipelineCreation() throws InvalidIRException {
        Graph inputSection = iComposeParallel(iPlugin(INPUT, "generator"), iPlugin(INPUT, "stdin")).toGraph();
        Graph filterSection = iIf(eEq(eEventValue("[foo]"), eEventValue("[bar]")),
                                    iPlugin(FILTER, "grok"),
                                    iPlugin(FILTER, "kv")).toGraph();
        Graph outputSection = iIf(eGt(eEventValue("[baz]"), eValue(1000)),
                                    iComposeParallel(
                                            iPlugin(OUTPUT, "s3"),
                                            iPlugin(OUTPUT, "elasticsearch")),
                                    iPlugin(OUTPUT, "stdout")).toGraph();

        Pipeline pipeline = new Pipeline(inputSection, filterSection, outputSection);
        System.out.println(pipeline.toString());
    }
}
