package org.logstash.config.ir;

import org.hamcrest.CoreMatchers;
import org.hamcrest.MatcherAssert;
import org.jruby.RubyArray;
import org.junit.Test;
import org.logstash.RubyUtil;

/**
 * Tests for {@link CompiledPipeline}.
 */
public class CompiledPipelineTest {

    @Test
    public void basicInputOutput() throws Exception {
        final CompiledPipeline pipeline = new CompiledPipeline(
            ConfigCompiler.configToPipelineIR("input {stdin{}} output{stdout{}}", false),
            new RubyPipelineMocks.MockPipeline()
        );
        final RubyArray batch = RubyUtil.RUBY.newArray();
        MatcherAssert.assertThat(
            pipeline.buildExecution().compute(batch, false, false),
            CoreMatchers.nullValue()
        );
    }

}
