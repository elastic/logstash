package org.logstash.config.ir;

import org.junit.Test;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public class ConfigCompilerTest {

    @Test
    public void testConfigToPipelineIR() throws Exception {
        final PipelineIR pipelineIR =
            ConfigCompiler.configToPipelineIR("input {stdin{}} output{stdout{}}", false);
        assertThat(pipelineIR.getOutputPluginVertices().size(), is(1));
        assertThat(pipelineIR.getFilterPluginVertices().size(), is(0));
    }
}
