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


package org.logstash.config.ir.compiler;

import javax.annotation.concurrent.NotThreadSafe;
import org.assertj.core.data.Percentage;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubySymbol;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Before;
import org.junit.Ignore;
import org.junit.Test;
import org.logstash.Event;
import org.logstash.instrument.metrics.MetricKeys;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.Assert.assertEquals;
import static org.logstash.RubyUtil.RUBY;
import static org.logstash.RubyUtil.RUBY_OUTPUT_DELEGATOR_CLASS;
import static org.logstash.instrument.metrics.MetricKeys.EVENTS_KEY;

@SuppressWarnings("rawtypes")
@NotThreadSafe
public class OutputDelegatorTest extends PluginDelegatorTestCase {

    private RubyHash pluginArgs;
    private RubyArray events;
    private static final int EVENT_COUNT = 7;
    public static final RubyClass FAKE_OUT_CLASS;

    static {
        FAKE_OUT_CLASS = RUBY.defineClass("FakeOutClass", RUBY.getObject(), FakeOutClass::new);
        FAKE_OUT_CLASS.defineAnnotatedMethods(FakeOutClass.class);
    }

    @Before
    public void setup() {
        super.setup();
        events = RUBY.newArray(EVENT_COUNT);
        for (int k = 0; k < EVENT_COUNT; k++) {
            events.add(k, new Event());
        }
        pluginArgs = RubyHash.newHash(RUBY);
        pluginArgs.put("id", "foo");
        pluginArgs.put("arg1", "val1");
    }

    @Override
    protected String getBaseMetricsPath() {
        return "output/foo";
    }

    @Test
    public void plainOutputPluginInitializesCleanly() {
        constructOutputDelegator();
    }

    @Test
    public void plainOutputPluginPushesPluginNameToMetric() {
        constructOutputDelegator();
        RubyHash metricStore = getMetricStore(new String[]{"output", "foo"});
        String pluginName = getMetricStringValue(metricStore, "name");

        assertEquals(FakeOutClass.configName(RUBY.getCurrentContext(), null).asJavaString(), pluginName);
    }

    @Test
    public void multiReceivePassesBatch() {
        OutputDelegatorExt outputDelegator = constructOutputDelegator();
        outputDelegator.multiReceive(events);
        assertEquals(events, FakeOutClass.latestInstance.getMultiReceiveArgs());
        assertEquals(EVENT_COUNT, ((RubyArray) FakeOutClass.latestInstance.getMultiReceiveArgs()).size());
    }

    @Test
    public void multiReceiveIncrementsEventCount() {
        OutputDelegatorExt outputDelegator = constructOutputDelegator();
        outputDelegator.multiReceive(events);

        assertEquals(EVENT_COUNT, getMetricLongValue("in"));
        assertEquals(EVENT_COUNT, getMetricLongValue("out"));
    }

    @Ignore("Test failing intermittently for some time. See https://github.com/elastic/logstash/issues/11956")
    @Test
    public void multiReceiveRecordsDurationInMillis() {
        final int delay = 100;
        final long millis;
        OutputDelegatorExt outputDelegator = constructOutputDelegator();
        final FakeOutClass instance = FakeOutClass.latestInstance;
        try {
            instance.setMultiReceiveDelay(delay);
            outputDelegator.multiReceive(events);
            millis = getMetricLongValue("duration_in_millis");
        } finally {
            instance.setMultiReceiveDelay(0);
        }

        assertThat(millis).isCloseTo((long)delay, Percentage.withPercentage(10));
    }

    @Test
    public void registersOutputPlugin() {
        OutputDelegatorExt outputDelegator = constructOutputDelegator();
        outputDelegator.register(RUBY.getCurrentContext());

        assertEquals(1, FakeOutClass.latestInstance.getRegisterCallCount());
    }

    @Test
    public void closesOutputPlugin() {
        OutputDelegatorExt outputDelegator = constructOutputDelegator();
        outputDelegator.doClose(RUBY.getCurrentContext());

        assertEquals(1, FakeOutClass.latestInstance.getCloseCallCount());
    }

    @Test
    public void singleConcurrencyStrategyIsDefault() {
        OutputDelegatorExt outputDelegator = constructOutputDelegator();
        IRubyObject concurrency = outputDelegator.concurrency(RUBY.getCurrentContext());
        assertEquals(RUBY.newSymbol("single"), concurrency);
    }

    @Test
    public void outputStrategyTests() {
        StrategyPair[] outputStrategies = new StrategyPair[]{
                new StrategyPair("shared", OutputStrategyExt.SharedOutputStrategyExt.class),
                new StrategyPair("single", OutputStrategyExt.SingleOutputStrategyExt.class),
                new StrategyPair("legacy", OutputStrategyExt.LegacyOutputStrategyExt.class)
        };

        for (StrategyPair pair : outputStrategies) {
            FakeOutClass.setOutStrategy(RUBY.getCurrentContext(), null, pair.symbol);
            OutputDelegatorExt outputDelegator = constructOutputDelegator();

            // test that output strategies are properly set
            IRubyObject outStrategy = outputDelegator.concurrency(RUBY.getCurrentContext());
            assertEquals(pair.symbol, outStrategy);

            // test that strategy classes are correctly instantiated
            IRubyObject strategyClass = outputDelegator.strategy();
            assertThat(strategyClass).isInstanceOf(pair.klazz);

            // test that metrics are properly set on the instance
            assertEquals(outputDelegator.namespacedMetric(), FakeOutClass.latestInstance.getMetricArgs());
        }
    }

    @Test
    public void outputStrategyMethodDelegationTests() {
        RubySymbol[] outputStrategies = new RubySymbol[]{
                RUBY.newSymbol("shared"),
                RUBY.newSymbol("single"),
                RUBY.newSymbol("legacy")
        };
        final ThreadContext context = RUBY.getCurrentContext();
        for (RubySymbol symbol : outputStrategies) {
            FakeOutClass.create().initialize(context);
            FakeOutClass.setOutStrategy(RUBY.getCurrentContext(), null, symbol);
            OutputDelegatorExt outputDelegator = constructOutputDelegator();
            outputDelegator.register(RUBY.getCurrentContext());
            final FakeOutClass instance = FakeOutClass.latestInstance;
            assertEquals(1, instance.getRegisterCallCount());

            outputDelegator.doClose(RUBY.getCurrentContext());
            assertEquals(1, instance.getCloseCallCount());

            outputDelegator.multiReceive(RUBY.newArray(0));
            assertEquals(1, instance.getMultiReceiveCallCount());
        }

    }

    private OutputDelegatorExt constructOutputDelegator() {
        return new OutputDelegatorExt(RUBY, RUBY_OUTPUT_DELEGATOR_CLASS).initialize(RUBY.getCurrentContext(), new IRubyObject[]{
            FAKE_OUT_CLASS,
            metric,
            executionContext,
            OutputStrategyExt.OutputStrategyRegistryExt.instance(RUBY.getCurrentContext(), null),
            pluginArgs
        });
    }

    private RubyHash getMetricStore() {
        return getMetricStore(new String[]{"output", "foo", EVENTS_KEY.asJavaString()});
    }

    private long getMetricLongValue(String symbolName) {
        return getMetricLongValue(getMetricStore(), symbolName);
    }

    private static class StrategyPair {
        RubySymbol symbol;
        Class klazz;

        StrategyPair(String symbolName, Class c) {
            this.symbol = RUBY.newSymbol(symbolName);
            this.klazz = c;
        }
    }
}
