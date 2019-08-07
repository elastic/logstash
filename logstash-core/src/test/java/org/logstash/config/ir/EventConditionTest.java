package org.logstash.config.ir;

import org.hamcrest.CoreMatchers;
import org.hamcrest.MatcherAssert;
import org.jruby.RubyArray;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyEventExtLibrary;

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
    @SuppressWarnings("rawtypes")
    public void testInclusionWithFieldInField() throws Exception {
        final PipelineIR pipelineIR = ConfigCompiler.configToPipelineIR(
                "input {mockinput{}} filter { " +
                        "mockfilter {} } " +
                        "output { " +
                        "  if [left] in [right] { " +
                        "    mockoutput{}" +
                        "  } }",
                false
        );

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

        MatcherAssert.assertThat(outputEvents.length, CoreMatchers.is(3));
        MatcherAssert.assertThat(outputEvents[0], CoreMatchers.is(leftIsString1));
        MatcherAssert.assertThat(outputEvents[1], CoreMatchers.is(rightIsList1));
        MatcherAssert.assertThat(outputEvents[2], CoreMatchers.is(nonStringValue1));
    }

    private Supplier<Consumer<Collection<RubyEvent>>> mockOutputSupplier() {
        return () -> events -> events.forEach(
                event -> EVENT_SINKS.get(runId).add(event)
        );
    }
}
