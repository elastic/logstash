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

import org.jruby.RubyArray;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.logstash.RubyUtil;
import org.logstash.common.ConfigVariableExpanderTest;
import org.logstash.common.EnvironmentVariableProvider;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.plugins.ConfigVariableExpander;

import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.LinkedTransferQueue;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Consumer;
import java.util.function.Supplier;

import static org.logstash.config.ir.CompiledPipelineTest.IDENTITY_FILTER;
import static org.logstash.ext.JrubyEventExtLibrary.RubyEvent;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public final class EventConditionTest extends RubyEnvTestCase {

    /**
     * Globally accessible map of test run id to a queue of {@link JrubyEventExtLibrary.RubyEvent}
     * that can be used by Ruby outputs.
     */
    private static final Map<Long, Collection<RubyEvent>> EVENT_SINKS =
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
    @SuppressWarnings({"rawtypes", "unchecked"})
    public void testInclusionWithFieldInField() throws Exception {
        final ConfigVariableExpander cve = ConfigVariableExpander.withoutSecret(EnvironmentVariableProvider.defaultProvider());
        final PipelineIR pipelineIR = ConfigCompiler.configToPipelineIR(
                IRHelpers.toSourceWithMetadata("input {mockinput{}} filter { " +
                        "mockfilter {} } " +
                        "output { " +
                        "  if [left] in [right] { " +
                        "    mockoutput{}" +
                        "  } }"),
                false,
                cve);

        // left list values never match
        RubyEvent leftIsList = RubyEvent.newRubyEvent(RubyUtil.RUBY);
        List listValues = Arrays.asList("foo", "bar", "baz");
        leftIsList.getEvent().setField("left", listValues);
        leftIsList.getEvent().setField("right", listValues);

        // left map values never match
        RubyEvent leftIsMap = RubyEvent.newRubyEvent(RubyUtil.RUBY);
        Map mapValues = Collections.singletonMap("foo", "bar");
        leftIsMap.getEvent().setField("left", mapValues);
        leftIsMap.getEvent().setField("right", mapValues);

        // left and right string values match when right.contains(left)
        RubyEvent leftIsString1 = RubyEvent.newRubyEvent(RubyUtil.RUBY);
        leftIsString1.getEvent().setField("left", "foo");
        leftIsString1.getEvent().setField("right", "zfooz");
        RubyEvent leftIsString2 = RubyEvent.newRubyEvent(RubyUtil.RUBY);
        leftIsString2.getEvent().setField("left", "foo");
        leftIsString2.getEvent().setField("right", "zzz");

        // right list value matches when right.contains(left)
        RubyEvent rightIsList1 = RubyEvent.newRubyEvent(RubyUtil.RUBY);
        rightIsList1.getEvent().setField("left", "bar");
        rightIsList1.getEvent().setField("right", listValues);
        RubyEvent rightIsList2 = RubyEvent.newRubyEvent(RubyUtil.RUBY);
        rightIsList2.getEvent().setField("left", "zzz");
        rightIsList2.getEvent().setField("right", listValues);

        // non-string values match when left == right
        RubyEvent nonStringValue1 = RubyEvent.newRubyEvent(RubyUtil.RUBY);
        nonStringValue1.getEvent().setField("left", 42L);
        nonStringValue1.getEvent().setField("right", 42L);
        RubyEvent nonStringValue2 = RubyEvent.newRubyEvent(RubyUtil.RUBY);
        nonStringValue2.getEvent().setField("left", 42L);
        nonStringValue2.getEvent().setField("right", 43L);

        RubyArray inputBatch = RubyUtil.RUBY.newArray(leftIsList, leftIsMap, leftIsString1, leftIsString2,
                rightIsList1, rightIsList2, nonStringValue1, nonStringValue2);

        new CompiledPipeline(
                pipelineIR,
                new CompiledPipelineTest.MockPluginFactory(
                        Collections.singletonMap("mockinput", () -> null),
                        Collections.singletonMap("mockfilter", () -> IDENTITY_FILTER),
                        Collections.singletonMap("mockoutput", mockOutputSupplier())
                )
        ).buildExecution().compute(inputBatch, false, false);
        final RubyEvent[] outputEvents = EVENT_SINKS.get(runId).toArray(new RubyEvent[0]);

        assertThat(outputEvents.length, is(3));
        assertThat(outputEvents[0], is(leftIsString1));
        assertThat(outputEvents[1], is(rightIsList1));
        assertThat(outputEvents[2], is(nonStringValue1));
    }

    @Test
    public void testConditionWithConstantValue() throws Exception {
        testConditionWithConstantValue("\"[abc]\"", 1);
    }

    @Test
    public void testConditionWithConstantFalseLiteralValue() throws Exception {
        testConditionWithConstantValue("\"false\"", 0);
    }

    @Test
    public void testConditionWithConstantEmptyStringValue() throws Exception {
        testConditionWithConstantValue("\"\"", 0);
    }

    @SuppressWarnings({"unchecked"})
    private void testConditionWithConstantValue(String condition, int expectedMatches) throws Exception {
        final ConfigVariableExpander cve = ConfigVariableExpander.withoutSecret(EnvironmentVariableProvider.defaultProvider());
        final PipelineIR pipelineIR = ConfigCompiler.configToPipelineIR(
                IRHelpers.toSourceWithMetadata("input {mockinput{}} filter { " +
                        "mockfilter {} } " +
                        "output { " +
                        "  if " + condition + " { " +
                        "    mockoutput{}" +
                        "  } }"),
                false,
                cve);

        new CompiledPipeline(
                pipelineIR,
                new CompiledPipelineTest.MockPluginFactory(
                        Collections.singletonMap("mockinput", () -> null),
                        Collections.singletonMap("mockfilter", () -> IDENTITY_FILTER),
                        Collections.singletonMap("mockoutput", mockOutputSupplier())
                ))
                .buildExecution()
                .compute(RubyUtil.RUBY.newArray(RubyEvent.newRubyEvent(RubyUtil.RUBY)), false, false);

        final Collection<RubyEvent> outputEvents = EVENT_SINKS.get(runId);
        assertThat(outputEvents.size(), is(expectedMatches));
    }

    private Supplier<Consumer<Collection<RubyEvent>>> mockOutputSupplier() {
        return () -> events -> events.forEach(
                event -> EVENT_SINKS.get(runId).add(event)
        );
    }

    private Supplier<IRubyObject> nullInputSupplier() {
        return () -> null;
    }

    @Test
    @SuppressWarnings({"rawtypes", "unchecked"})
    public void testConditionWithSecretStoreVariable() throws InvalidIRException {
        ConfigVariableExpander cve = ConfigVariableExpanderTest.getFakeCve(
                Collections.singletonMap("secret_key", "s3cr3t"), Collections.emptyMap());

        final PipelineIR pipelineIR = ConfigCompiler.configToPipelineIR(
                IRHelpers.toSourceWithMetadata("input {mockinput{}} " +
                        "output { " +
                        "  if [left] == \"${secret_key}\" { " +
                        "    mockoutput{}" +
                        "  } }"),
                false,
                cve);

        // left and right string values match when right.contains(left)
        RubyEvent leftIsString1 = RubyEvent.newRubyEvent(RubyUtil.RUBY);
        leftIsString1.getEvent().setField("left", "s3cr3t");

        RubyArray inputBatch = RubyUtil.RUBY.newArray(leftIsString1);

        new CompiledPipeline(
                pipelineIR,
                new CompiledPipelineTest.MockPluginFactory(
                        Collections.singletonMap("mockinput", nullInputSupplier()),
                        Collections.emptyMap(), // no filters
                        Collections.singletonMap("mockoutput", mockOutputSupplier())
                )
        ).buildExecution().compute(inputBatch, false, false);
        final RubyEvent[] outputEvents = EVENT_SINKS.get(runId).toArray(new RubyEvent[0]);

        assertThat(outputEvents.length, is(1));
        assertThat(outputEvents[0], is(leftIsString1));
    }
}
