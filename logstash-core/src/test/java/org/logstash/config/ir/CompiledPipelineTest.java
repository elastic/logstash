/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.config.ir;

import co.elastic.logstash.api.Codec;
import com.google.common.base.Strings;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.LinkedTransferQueue;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Consumer;
import java.util.function.Supplier;
import org.hamcrest.CoreMatchers;
import org.hamcrest.MatcherAssert;
import org.jruby.RubyArray;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.logstash.ConvertedList;
import org.logstash.ConvertedMap;
import org.logstash.Event;
import org.logstash.RubyUtil;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.compiler.AbstractFilterDelegatorExt;
import org.logstash.config.ir.compiler.AbstractOutputDelegatorExt;
import org.logstash.config.ir.compiler.FilterDelegatorExt;
import org.logstash.config.ir.compiler.PluginFactory;
import org.logstash.ext.JrubyEventExtLibrary;
import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Filter;
import co.elastic.logstash.api.Input;
import co.elastic.logstash.api.Context;

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
    static final IRubyObject IDENTITY_FILTER = RubyUtil.RUBY.evalScriptlet(
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
    static final IRubyObject ADD_FIELD_FILTER = RubyUtil.RUBY.evalScriptlet(
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

    @SuppressWarnings({"unchecked"})
    @Test
    public void buildsTrivialPipeline() throws Exception {
        final PipelineIR pipelineIR = ConfigCompiler.configToPipelineIR(
                IRHelpers.toSourceWithMetadata("input {mockinput{}} output{mockoutput{}}"), false
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

    @SuppressWarnings({"unchecked"})
    @Test
    public void buildsStraightPipeline() throws Exception {
        final PipelineIR pipelineIR = ConfigCompiler.configToPipelineIR(
                IRHelpers.toSourceWithMetadata("input {mockinput{}} filter { mockfilter {} mockfilter {} mockfilter {}} output{mockoutput{}}"),
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

    @SuppressWarnings({"unchecked"})
    @Test
    public void buildsForkedPipeline() throws Exception {
        final PipelineIR pipelineIR = ConfigCompiler.configToPipelineIR(IRHelpers.toSourceWithMetadata(
            "input {mockinput{}} filter { " +
                "if [foo] != \"bar\" { " +
                "mockfilter {} " +
                "mockaddfilter {} " +
                "if [foo] != \"bar\" { " +
                "mockfilter {} " +
                "}} " +
                "} output {mockoutput{} }"),
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
    public void correctlyCompilesEquals() throws Exception {
        final String eq = "==";
        assertCorrectFieldComparison(eq, 6, false);
        assertCorrectFieldComparison(eq, 7, true);
        assertCorrectFieldComparison(eq, 8, false);
        assertCorrectValueComparison(eq, 6, false);
        assertCorrectValueComparison(eq, 7, true);
        assertCorrectValueComparison(eq, 8, false);
        assertCorrectFieldToFieldComparison(eq, 7, 6, false);
        assertCorrectFieldToFieldComparison(eq, 7, 7, true);
        assertCorrectFieldToFieldComparison(eq, 7, 8, false);
    }

    @Test
    public void correctlyCompilesNotEquals() throws Exception {
        final String eq = "!=";
        assertCorrectFieldComparison(eq, 6, true);
        assertCorrectFieldComparison(eq, 7, false);
        assertCorrectFieldComparison(eq, 8, true);
        assertCorrectValueComparison(eq, 6, true);
        assertCorrectValueComparison(eq, 7, false);
        assertCorrectValueComparison(eq, 8, true);
        assertCorrectFieldToFieldComparison(eq, 7, 6, true);
        assertCorrectFieldToFieldComparison(eq, 7, 7, false);
        assertCorrectFieldToFieldComparison(eq, 7, 8, true);
    }

    @Test
    public void correctlyCompilesGreaterThan() throws Exception {
        final String gt = ">";
        assertCorrectFieldComparison(gt, 6, true);
        assertCorrectFieldComparison(gt, 7, false);
        assertCorrectFieldComparison(gt, 8, false);
        assertCorrectValueComparison(gt, 6, true);
        assertCorrectValueComparison(gt, 7, false);
        assertCorrectValueComparison(gt, 8, false);
        assertCorrectFieldToFieldComparison(gt, 7, 6, true);
        assertCorrectFieldToFieldComparison(gt, 7, 7, false);
        assertCorrectFieldToFieldComparison(gt, 7, 8, false);
    }

    @Test
    public void correctlyCompilesLessThan() throws Exception {
        final String lt = "<";
        assertCorrectFieldComparison(lt, 6, false);
        assertCorrectFieldComparison(lt, 7, false);
        assertCorrectFieldComparison(lt, 8, true);
        assertCorrectValueComparison(lt, 6, false);
        assertCorrectValueComparison(lt, 7, false);
        assertCorrectValueComparison(lt, 8, true);
        assertCorrectFieldToFieldComparison(lt, 7, 6, false);
        assertCorrectFieldToFieldComparison(lt, 7, 7, false);
        assertCorrectFieldToFieldComparison(lt, 7, 8, true);
    }

    @Test
    public void correctlyCompilesLessOrEqualThan() throws Exception {
        final String lte = "<=";
        assertCorrectFieldComparison(lte, 6, false);
        assertCorrectFieldComparison(lte, 7, true);
        assertCorrectFieldComparison(lte, 8, true);
        assertCorrectValueComparison(lte, 6, false);
        assertCorrectValueComparison(lte, 7, true);
        assertCorrectValueComparison(lte, 8, true);
        assertCorrectFieldToFieldComparison(lte, 7, 6, false);
        assertCorrectFieldToFieldComparison(lte, 7, 7, true);
        assertCorrectFieldToFieldComparison(lte, 7, 8, true);
    }

    @Test
    public void correctlyCompilesGreaterOrEqualThan() throws Exception {
        final String gte = ">=";
        assertCorrectFieldComparison(gte, 6, true);
        assertCorrectFieldComparison(gte, 7, true);
        assertCorrectFieldComparison(gte, 8, false);
        assertCorrectValueComparison(gte, 6, true);
        assertCorrectValueComparison(gte, 7, true);
        assertCorrectValueComparison(gte, 8, false);
        assertCorrectFieldToFieldComparison(gte, 7, 6, true);
        assertCorrectFieldToFieldComparison(gte, 7, 7, true);
        assertCorrectFieldToFieldComparison(gte, 7, 8, false);
    }

    @Test
    public void correctlyCompilesRegexMatchesWithConstant() throws InvalidIRException {
        verifyRegex("=~", 1);
    }

    @Test
    public void correctlyCompilesRegexNoMatchesWithConstant() throws InvalidIRException {
        verifyRegex("!~", 0);
    }

    @SuppressWarnings({"unchecked"})
    private void verifyRegex(String operator, int expectedEvents)
            throws InvalidIRException {
        final Event event = new Event();

        final JrubyEventExtLibrary.RubyEvent testEvent =
                JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, event);

        new CompiledPipeline(
                ConfigCompiler.configToPipelineIR(
                        IRHelpers.toSourceWithMetadata("input {mockinput{}} output { " +
                                String.format("if \"z\" %s /z/ { ", operator) +
                                " mockoutput{} } }"),
                        false
                ),
                new CompiledPipelineTest.MockPluginFactory(
                        Collections.singletonMap("mockinput", () -> null),
                        Collections.singletonMap("mockaddfilter", () -> null),
                        Collections.singletonMap("mockoutput", mockOutputSupplier())
                )
        ).buildExecution()
                .compute(RubyUtil.RUBY.newArray(testEvent), false, false);
        final Collection<JrubyEventExtLibrary.RubyEvent> outputEvents = EVENT_SINKS.get(runId);
        MatcherAssert.assertThat(outputEvents.size(), CoreMatchers.is(expectedEvents));
        MatcherAssert.assertThat(outputEvents.contains(testEvent), CoreMatchers.is(expectedEvents >= 1));
        outputEvents.clear();
    }

    @SuppressWarnings({"unchecked"})
    @Test
    public void equalityCheckOnCompositeField() throws Exception {
        final PipelineIR pipelineIR = ConfigCompiler.configToPipelineIR(
                IRHelpers.toSourceWithMetadata("input {mockinput{}} filter { if 4 == [list] { mockaddfilter {} } if 5 == [map] { mockaddfilter {} } } output {mockoutput{} }"),
                false
        );
        final Collection<String> s = new ArrayList<>();
        s.add("foo");
        final Map<String, Object> m = new HashMap<>();
        m.put("foo", "bar");
        final JrubyEventExtLibrary.RubyEvent testEvent =
                JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, new Event());
        testEvent.getEvent().setField("list", ConvertedList.newFromList(s));
        testEvent.getEvent().setField("map", ConvertedMap.newFromMap(m));

        final Map<String, Supplier<IRubyObject>> filters = new HashMap<>();
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

    @SuppressWarnings({"unchecked"})
    @Test
    public void conditionalWithNullField() throws Exception {
        final PipelineIR pipelineIR = ConfigCompiler.configToPipelineIR(
                IRHelpers.toSourceWithMetadata("input {mockinput{}} filter { if [foo] == [bar] { mockaddfilter {} } } output {mockoutput{} }"),
                false
        );
        final JrubyEventExtLibrary.RubyEvent testEvent =
                JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, new Event());
        final Map<String, Supplier<IRubyObject>> filters = new HashMap<>();
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
        MatcherAssert.assertThat(testEvent.getEvent().getField("foo"), CoreMatchers.is("bar"));
    }

    @SuppressWarnings({"unchecked"})
    @Test
    public void conditionalNestedMetaFieldPipeline() throws Exception {
        final PipelineIR pipelineIR = ConfigCompiler.configToPipelineIR(
                IRHelpers.toSourceWithMetadata("input {mockinput{}} filter { if [@metadata][foo][bar] { mockaddfilter {} } } output {mockoutput{} }"),
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

    @SuppressWarnings({"unchecked"})
    @Test
    public void moreThan255Parents() throws Exception {
        final PipelineIR pipelineIR = ConfigCompiler.configToPipelineIR(
                IRHelpers.toSourceWithMetadata("input {mockinput{}} filter { " +
                "if [foo] != \"bar\" { " +
                "mockfilter {} " +
                "mockaddfilter {} " +
                "if [foo] != \"bar\" { " +
                "mockfilter {} " +
                Strings.repeat("} else if [foo] != \"bar\" {" +
                    "mockfilter {} ", 300) + " } } " +
                "} output {mockoutput{} }"),
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

    private void assertCorrectValueComparison(final String op, final int value,
        final boolean expected) throws Exception {
        final Event event = new Event();
        verifyComparison(expected, String.format("7 %s %d ", op, value), event);
    }

    private void assertCorrectFieldComparison(final String op, final int value,
        final boolean expected) throws Exception {
        final Event event = new Event();
        event.setField("baz", value);
        verifyComparison(expected, String.format("7 %s [baz]", op), event);
    }

    private void assertCorrectFieldToFieldComparison(final String op, final int value1,
        final int value2, final boolean expected) throws Exception {
        final Event event = new Event();
        event.setField("brr", value1);
        event.setField("baz", value2);
        verifyComparison(expected, String.format("[brr] %s [baz]", op), event);
    }

    @SuppressWarnings({"unchecked"})
    private void verifyComparison(final boolean expected, final String conditional, final Event event)
            throws InvalidIRException {
        final JrubyEventExtLibrary.RubyEvent testEvent =
            JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, event);

        new CompiledPipeline(
            ConfigCompiler.configToPipelineIR(
                    IRHelpers.toSourceWithMetadata("input {mockinput{}} filter { " +
                    String.format("if %s { ", conditional) +
                    " mockaddfilter {} " +
                    "} " +
                    "} output {mockoutput{} }"),
                false
            ),
            new CompiledPipelineTest.MockPluginFactory(
                Collections.singletonMap("mockinput", () -> null),
                Collections.singletonMap("mockaddfilter", () -> ADD_FIELD_FILTER),
                Collections.singletonMap("mockoutput", mockOutputSupplier())
            )
        ).buildExecution()
            .compute(RubyUtil.RUBY.newArray(testEvent), false, false);
        final Collection<JrubyEventExtLibrary.RubyEvent> outputEvents = EVENT_SINKS.get(runId);
        MatcherAssert.assertThat(outputEvents.size(), CoreMatchers.is(1));
        MatcherAssert.assertThat(outputEvents.contains(testEvent), CoreMatchers.is(true));
        MatcherAssert.assertThat(
            event.getField("foo"), CoreMatchers.is(expected ? "bar" : null)
        );
        outputEvents.clear();
    }

    private Supplier<Consumer<Collection<JrubyEventExtLibrary.RubyEvent>>> mockOutputSupplier() {
        return () -> events -> events.forEach(
            event -> EVENT_SINKS.get(runId).add(event)
        );
    }

    /**
     * Configurable Mock {@link PluginFactory}
     */
    static final class MockPluginFactory implements PluginFactory {

        private final Map<String, Supplier<IRubyObject>> inputs;

        private final Map<String, Supplier<IRubyObject>> filters;

        private final Map<String, Supplier<Consumer<Collection<JrubyEventExtLibrary.RubyEvent>>>> outputs;

        MockPluginFactory(final Map<String, Supplier<IRubyObject>> inputs,
            final Map<String, Supplier<IRubyObject>> filters,
            final Map<String, Supplier<Consumer<Collection<JrubyEventExtLibrary.RubyEvent>>>> outputs
        ) {
            this.inputs = inputs;
            this.filters = filters;
            this.outputs = outputs;
        }

        @Override
        public IRubyObject buildInput(final RubyString name, SourceWithMetadata source,
                                      final IRubyObject args, Map<String, Object> pluginArgs) {
            return setupPlugin(name, inputs);
        }

        @Override
        public AbstractOutputDelegatorExt buildOutput(final RubyString name, SourceWithMetadata source,
                                                      final IRubyObject args, Map<String, Object> pluginArgs) {
            return PipelineTestUtil.buildOutput(setupPlugin(name, outputs));
        }

        @Override
        public AbstractFilterDelegatorExt buildFilter(final RubyString name, SourceWithMetadata source,
                                                      final IRubyObject args, Map<String, Object> pluginArgs) {
            final RubyObject configNameDouble = org.logstash.config.ir.PluginConfigNameMethodDouble.create(name);
            return new FilterDelegatorExt(
                RubyUtil.RUBY, RubyUtil.FILTER_DELEGATOR_CLASS)
                    .initForTesting(setupPlugin(name, filters), configNameDouble);
        }

        @Override
        public IRubyObject buildCodec(final RubyString name, SourceWithMetadata source, final IRubyObject args,
                                      Map<String, Object> pluginArgs) {
            throw new IllegalStateException("No codec setup expected in this test.");
        }

        @Override
        public Codec buildDefaultCodec(String codecName) {
            return null;
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

        @Override
        public Input buildInput(final String name, final String id, final Configuration configuration, final Context context) {
            return null;
        }

        @Override
        public Filter buildFilter(final String name, final String id,
                                  final Configuration configuration, final Context context) {
            return null;
        }
    }
}
