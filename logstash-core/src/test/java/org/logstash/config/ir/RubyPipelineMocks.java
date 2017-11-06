package org.logstash.config.ir;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyInteger;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.config.ir.compiler.RubyIntegration;

public final class RubyPipelineMocks {

    private static final String MOCK_OUTPUT_CLASSNAME = "MockOutput";

    private static final RubyClass MOCK_OUTPUT;

    static {
        MOCK_OUTPUT = RubyUtil.RUBY.defineClassUnder(
            MOCK_OUTPUT_CLASSNAME, RubyUtil.RUBY.getObject(), RubyPipelineMocks.MockOutput::new,
            RubyUtil.LOGSTASH_MODULE
        );
        MOCK_OUTPUT.defineAnnotatedMethods(RubyPipelineMocks.MockOutput.class);
    }

    public static final class MockPipeline implements RubyIntegration.Pipeline {
        @Override
        public IRubyObject buildInput(final RubyString name, final RubyInteger line,
            final RubyInteger column,
            final IRubyObject args) {
            return null;
        }

        @Override
        public IRubyObject buildOutput(final RubyString name, final RubyInteger line,
            final RubyInteger column,
            final IRubyObject args) {
            final IRubyObject output = MOCK_OUTPUT.newInstance(
                RubyUtil.RUBY.getCurrentContext(), Block.NULL_BLOCK
            );
            return output;
        }

        @Override
        public RubyIntegration.Filter buildFilter(final RubyString name,
            final RubyInteger line, final RubyInteger column,
            final IRubyObject args) {
            return null;
        }

        @Override
        public RubyIntegration.Filter buildCodec(final RubyString name,
            final IRubyObject args) {
            return null;
        }
    }

    @JRubyClass(name = MOCK_OUTPUT_CLASSNAME)
    public static final class MockOutput extends RubyObject {

        public MockOutput(final Ruby runtime, final RubyClass metaClass) {
            super(runtime, metaClass);
        }

        @JRubyMethod(name = "multi_receive", required = 1)
        public IRubyObject multiReceive(final ThreadContext threadContext, final IRubyObject events) {
            return threadContext.nil;
        }
    }
}
