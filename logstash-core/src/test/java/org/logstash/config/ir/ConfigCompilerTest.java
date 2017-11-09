package org.logstash.config.ir;

import org.jruby.Ruby;
import org.junit.Test;
import org.logstash.LogstashSession;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public class ConfigCompilerTest {

    @Test
    public void testConfigToPipelineIR() throws Exception {
        try (final LogstashSession logstash = LogstashSession.getOrCreate(Ruby.newInstance())) {
            final PipelineIR pipelineIR = logstash.getConfigCompiler().configToPipelineIR(
                "input {stdin{}} output{stdout{}}", false
            );
            assertThat(pipelineIR.getOutputPluginVertices().size(), is(1));
            assertThat(pipelineIR.getFilterPluginVertices().size(), is(0));
        }
    }
}
