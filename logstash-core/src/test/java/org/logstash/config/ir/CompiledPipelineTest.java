package org.logstash.config.ir;

import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.LinkedTransferQueue;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Supplier;
import org.hamcrest.CoreMatchers;
import org.hamcrest.MatcherAssert;
import org.jruby.RubyArray;
import org.jruby.RubyInteger;
import org.jruby.RubyString;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.logstash.Event;
import org.logstash.RubyUtil;
import org.logstash.config.ir.compiler.FilterDelegatorExt;
import org.logstash.config.ir.compiler.OutputDelegatorExt;
import org.logstash.config.ir.compiler.OutputStrategyExt;
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
    private static final Map<Long, Collection<JrubyEventExtLibrary.RubyEvent>> EVENT_SINKS =
        new ConcurrentHashMap<>();

    /**
     * Mock filter that does not modify the batch.
     */
    private static final IRubyObject IDENTITY_FILTER = RubyUtil.RUBY.evalScriptlet(
        String.join(
            "\n",
            "output = Object.new",
            "output.define_singleton_method(:multi_filter) do |batch|",
            "batch",
            "end",
            "output"
        )
    );

    /**
     * Mock filter that adds the value 'bar' to the field 'foo' for every event in the batch.
     */
    private static final IRubyObject ADD_FIELD_FILTER = RubyUtil.RUBY.evalScriptlet(
        String.join(
            "\n",
            "output = Object.new",
            "output.define_singleton_method(:multi_filter) do |batch|",
            "batch.each { |e| e.set('foo', 'bar')}",
            "end",
            "output"
        )
    );

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
                Collections.singletonMap("mockfilter", () -> IDENTITY_FILTER),
                Collections.singletonMap("mockoutput", mockOutputSupplier())
            )
        ).buildExecution().compute(RubyUtil.RUBY.newArray(testEvent), false, false);
        final Collection<JrubyEventExtLibrary.RubyEvent> outputEvents = EVENT_SINKS.get(runId);
        MatcherAssert.assertThat(outputEvents.size(), CoreMatchers.is(1));
        MatcherAssert.assertThat(outputEvents.contains(testEvent), CoreMatchers.is(true));
    }

    @Test
    public void buildsForkedPipeline() throws Exception {
        final PipelineIR pipelineIR = ConfigCompiler.configToPipelineIR(
            "input {mockinput{}} filter { " +
                "if [foo] != \"bar\" { " +
                "mockfilter {} " +
                "mockaddfilter {} " +
                "if [foo] != \"bar\" { " +
                "mockfilter {} " +
                "}} " +
                "} output {mockoutput{} }",
            false
        );
        final JrubyEventExtLibrary.RubyEvent testEvent =
            JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, new Event());
        final Map<String, Supplier<IRubyObject>> filters = new HashMap<>();
        filters.put("mockfilter", () -> IDENTITY_FILTER);
        filters.put("mockaddfilter", () -> ADD_FIELD_FILTER);
        new CompiledPipeline(
            pipelineIR,
            new CompiledPipelineTest.MockPluginFactory(
                Collections.singletonMap("mockinput", () -> null),
                filters,
                Collections.singletonMap("mockoutput", mockOutputSupplier())
            )
        ).buildExecution().compute(RubyUtil.RUBY.newArray(testEvent), false, false);
        final Collection<JrubyEventExtLibrary.RubyEvent> outputEvents = EVENT_SINKS.get(runId);
        MatcherAssert.assertThat(outputEvents.size(), CoreMatchers.is(1));
        MatcherAssert.assertThat(outputEvents.contains(testEvent), CoreMatchers.is(true));
    }

    @Test
    public void conditionalNestedMetaFieldPipeline() throws Exception {
        final PipelineIR pipelineIR = ConfigCompiler.configToPipelineIR(
            "input {mockinput{}} filter { if [@metadata][foo][bar] { mockaddfilter {} } } output {mockoutput{} }",
            false
        );
        final JrubyEventExtLibrary.RubyEvent testEvent =
            JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, new Event());
        final Map<String, Supplier<IRubyObject>> filters = new HashMap<>();
        filters.put("mockfilter", () -> IDENTITY_FILTER);
        filters.put("mockaddfilter", () -> ADD_FIELD_FILTER);
        new CompiledPipeline(
            pipelineIR,
            new CompiledPipelineTest.MockPluginFactory(
                Collections.singletonMap("mockinput", () -> null),
                filters,
                Collections.singletonMap("mockoutput", mockOutputSupplier())
            )
        ).buildExecution().compute(RubyUtil.RUBY.newArray(testEvent), false, false);
        final Collection<JrubyEventExtLibrary.RubyEvent> outputEvents = EVENT_SINKS.get(runId);
        MatcherAssert.assertThat(outputEvents.size(), CoreMatchers.is(1));
        MatcherAssert.assertThat(outputEvents.contains(testEvent), CoreMatchers.is(true));
        MatcherAssert.assertThat(testEvent.getEvent().getField("foo"), CoreMatchers.nullValue());
    }

    private Supplier<OutputStrategyExt.AbstractOutputStrategyExt> mockOutputSupplier() {
        return () -> new OutputStrategyExt.SimpleAbstractOutputStrategyExt(RubyUtil.RUBY, RubyUtil.RUBY.getObject()) {
            @Override
            @SuppressWarnings("unchecked")
            protected IRubyObject output(final ThreadContext context, final IRubyObject events) {
                ((RubyArray) events).forEach(event -> EVENT_SINKS.get(runId).add((JrubyEventExtLibrary.RubyEvent) event));
                return this;
            }
        };
    }

    /**
     * Configurable Mock {@link RubyIntegration.PluginFactory}
     */
    private static final class MockPluginFactory implements RubyIntegration.PluginFactory {

        private final Map<String, Supplier<IRubyObject>> inputs;

        private final Map<String, Supplier<IRubyObject>> filters;

        private final Map<String, Supplier<OutputStrategyExt.AbstractOutputStrategyExt>> outputs;

        MockPluginFactory(final Map<String, Supplier<IRubyObject>> inputs,
            final Map<String, Supplier<IRubyObject>> filters,
            final Map<String, Supplier<OutputStrategyExt.AbstractOutputStrategyExt>> outputs) {
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
        public OutputDelegatorExt buildOutput(final RubyString name, final RubyInteger line,
            final RubyInteger column, final IRubyObject args) {
            return new OutputDelegatorExt(
                RubyUtil.RUBY, RubyUtil.OUTPUT_DELEGATOR_CLASS)
                .initForTesting(setupPlugin(name, outputs));
        }

        @Override
        public FilterDelegatorExt buildFilter(final RubyString name, final RubyInteger line,
            final RubyInteger column, final IRubyObject args) {
            return new FilterDelegatorExt(
                RubyUtil.RUBY, RubyUtil.OUTPUT_DELEGATOR_CLASS)
                .initForTesting(setupPlugin(name, filters));
        }

        @Override
        public IRubyObject buildCodec(final RubyString name, final IRubyObject args) {
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
}
