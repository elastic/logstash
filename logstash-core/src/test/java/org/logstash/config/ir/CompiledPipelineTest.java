package org.logstash.config.ir;

import java.util.Collection;
import java.util.Collections;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.LinkedTransferQueue;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Supplier;
import org.hamcrest.CoreMatchers;
import org.hamcrest.MatcherAssert;
import org.jruby.RubyInteger;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.logstash.Event;
import org.logstash.RubyUtil;
import org.logstash.config.ir.compiler.RubyIntegration;
import org.logstash.ext.JrubyEventExtLibrary;

/**
 * Tests for {@link CompiledPipeline}.
 */
public final class CompiledPipelineTest extends RubyEnvTestCase {

    /**
     * Globally accessible map of test run id to a queue of {@link JrubyEventExtLibrary.RubyEvent}
     * that can be used by Ruby outputs.
     */
    public static final Map<Long, Collection<JrubyEventExtLibrary.RubyEvent>> EVENT_SINKS =
        new ConcurrentHashMap<>();

    private static final AtomicLong TEST_RUN = new AtomicLong();

    /**
     * Unique identifier for this test run so that mock test outputs can correctly identify
     * their event sink in {@link #EVENT_SINKS}.
     */
    private long runId;

    @Before
    public void beforeEach() {
        runId = TEST_RUN.incrementAndGet();
        EVENT_SINKS.put(runId, new LinkedTransferQueue<>());
    }

    @After
    public void afterEach() {
        EVENT_SINKS.remove(runId);
    }

    @Test
    public void buildsTrivialPipeline() throws Exception {
        final PipelineIR pipelineIR = ConfigCompiler.configToPipelineIR(
            "input {mockinput{}} output{mockoutput{}}", false
        );
        final JrubyEventExtLibrary.RubyEvent testEvent =
            JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, new Event());
        new CompiledPipeline(pipelineIR,
            new CompiledPipelineTest.MockPluginFactory(
                Collections.singletonMap("mockinput", () -> null),
                Collections.emptyMap(),
                Collections.singletonMap("mockoutput", mockOutputSupplier())
            )
        ).buildExecution().compute(RubyUtil.RUBY.newArray(testEvent), false, false);
        final Collection<JrubyEventExtLibrary.RubyEvent> outputEvents = EVENT_SINKS.get(runId);
        MatcherAssert.assertThat(outputEvents.size(), CoreMatchers.is(1));
        MatcherAssert.assertThat(outputEvents.contains(testEvent), CoreMatchers.is(true));
    }

    @Test
    public void buildsStraightPipeline() throws Exception {
        final PipelineIR pipelineIR = ConfigCompiler.configToPipelineIR(
            "input {mockinput{}} filter { mockfilter {} mockfilter {} mockfilter {}} output{mockoutput{}}",
            false
        );
        final JrubyEventExtLibrary.RubyEvent testEvent =
            JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, new Event());
        new CompiledPipeline(
            pipelineIR,
            new CompiledPipelineTest.MockPluginFactory(
                Collections.singletonMap("mockinput", () -> null),
                Collections.singletonMap("mockfilter", CompiledPipelineTest.IdentityFilter::new),
                Collections.singletonMap("mockoutput", mockOutputSupplier())
            )
        ).buildExecution().compute(RubyUtil.RUBY.newArray(testEvent), false, false);
        final Collection<JrubyEventExtLibrary.RubyEvent> outputEvents = EVENT_SINKS.get(runId);
        MatcherAssert.assertThat(outputEvents.size(), CoreMatchers.is(1));
        MatcherAssert.assertThat(outputEvents.contains(testEvent), CoreMatchers.is(true));
    }

    private Supplier<IRubyObject> mockOutputSupplier() {
        return () -> RubyUtil.RUBY.evalScriptlet(
            String.join(
                "\n",
                "output = Object.new",
                "output.define_singleton_method(:multi_receive) do |batch|",
                String.format(
                    "batch.to_a.each {|e| org.logstash.config.ir.CompiledPipelineTest::EVENT_SINKS.get(%d).put(e)}",
                    runId
                ),
                "end",
                "output"
            )
        );
    }

    /**
     * Configurable Mock {@link RubyIntegration.PluginFactory}
     */
    private static final class MockPluginFactory implements RubyIntegration.PluginFactory {

        private final Map<String, Supplier<IRubyObject>> inputs;

        private final Map<String, Supplier<RubyIntegration.Filter>> filters;

        private final Map<String, Supplier<IRubyObject>> outputs;

        MockPluginFactory(final Map<String, Supplier<IRubyObject>> inputs,
            final Map<String, Supplier<RubyIntegration.Filter>> filters,
            final Map<String, Supplier<IRubyObject>> outputs) {
            this.inputs = inputs;
            this.filters = filters;
            this.outputs = outputs;
        }

        @Override
        public IRubyObject buildInput(final RubyString name, final RubyInteger line,
            final RubyInteger column, final IRubyObject args) {
            return setupPlugin(name, inputs);
        }

        @Override
        public IRubyObject buildOutput(final RubyString name, final RubyInteger line,
            final RubyInteger column, final IRubyObject args) {
            return setupPlugin(name, outputs);
        }

        @Override
        public RubyIntegration.Filter buildFilter(final RubyString name, final RubyInteger line,
            final RubyInteger column, final IRubyObject args) {
            return setupPlugin(name, filters);
        }

        @Override
        public RubyIntegration.Filter buildCodec(final RubyString name, final IRubyObject args) {
            throw new IllegalStateException("No codec setup expected in this test.");
        }

        private static <T> T setupPlugin(final RubyString name,
            final Map<String, Supplier<T>> suppliers) {
            final String key = name.asJavaString();
            if (!suppliers.containsKey(key)) {
                throw new IllegalStateException(
                    String.format("Tried to set up unexpected plugin %s.", key)
                );
            }
            return suppliers.get(name.asJavaString()).get();
        }
    }

    /**
     * Mock filter that does not modify the batch.
     */
    private static final class IdentityFilter implements RubyIntegration.Filter {
        @Override
        public IRubyObject toRuby() {
            return RubyUtil.RUBY.evalScriptlet(
                String.join(
                    "\n",
                    "output = Object.new",
                    "output.define_singleton_method(:multi_filter) do |batch|",
                    "batch",
                    "end",
                    "output"
                )
            );
        }

        @Override
        public boolean hasFlush() {
            return false;
        }

        @Override
        public boolean periodicFlush() {
            return false;
        }

        @Override
        public void register() {
        }
    }
}
