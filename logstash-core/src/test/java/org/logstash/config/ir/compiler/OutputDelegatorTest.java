package org.logstash.config.ir.compiler;

import org.assertj.core.data.Percentage;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.java.proxies.ConcreteJavaProxy;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Before;
import org.junit.Test;
import org.logstash.Event;
import org.logstash.config.ir.RubyEnvTestCase;
import org.logstash.execution.ExecutionContextExt;
import org.logstash.instrument.metrics.NamespacedMetricExt;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;
import static org.logstash.RubyUtil.EXECUTION_CONTEXT_CLASS;
import static org.logstash.RubyUtil.NAMESPACED_METRIC_CLASS;
import static org.logstash.RubyUtil.OUTPUT_DELEGATOR_CLASS;
import static org.logstash.RubyUtil.RUBY;

public class OutputDelegatorTest extends RubyEnvTestCase {

    private FakeOutClass fakeOutClass;
    private NamespacedMetricExt metric;
    private ExecutionContextExt executionContext;
    private RubyHash pluginArgs;
    private RubyArray events;
    private static final int EVENT_COUNT = 7;
    static RubyClass FAKE_OUT_CLASS;

    static {
        FAKE_OUT_CLASS = RUBY.defineClass("FakeOutClass", RUBY.getObject(), FakeOutClass::new);
        FAKE_OUT_CLASS.defineAnnotatedMethods(FakeOutClass.class);
    }

    @Before
    public void setup() {
        events = RUBY.newArray(EVENT_COUNT);
        for (int k = 0; k < EVENT_COUNT; k++) {
            events.add(k, new Event());
        }
        fakeOutClass = FakeOutClass.create();
        RubyArray namespaces = RubyArray.newArray(RUBY, 1);
        namespaces.add(0, RubySymbol.newSymbol(RUBY, "output"));
        IRubyObject metricWithCollector =
                runRubyScript("require \"logstash/instrument/collector\"\n" +
                        "metricWithCollector = LogStash::Instrument::Metric.new(LogStash::Instrument::Collector.new)");

        metric = (NamespacedMetricExt) new NamespacedMetricExt(RUBY, NAMESPACED_METRIC_CLASS)
                .initialize(RUBY.getCurrentContext(), metricWithCollector, namespaces);
        executionContext = new ExecutionContextExt(RUBY, EXECUTION_CONTEXT_CLASS);
        pluginArgs = RubyHash.newHash(RUBY);
        pluginArgs.put("id", "foo");
        pluginArgs.put("arg1", "val1");
    }

    @Test
    public void plainOutputPluginInitializesCleanly() {
        OutputDelegatorExt outputDelegator = constructOutputDelegator();
    }

    @Test
    public void plainOutputPluginPushesPluginNameToMetric() {
        OutputDelegatorExt outputDelegator = constructOutputDelegator();
        RubyHash metricStore = getMetricStore(new String[]{"output", "foo"});
        String pluginName = getMetricStringValue(metricStore, "name");

        assertEquals(fakeOutClass.configName(RUBY.getCurrentContext()).asJavaString(), pluginName);
    }

    @Test
    public void multiReceivePassesBatch() {
        OutputDelegatorExt outputDelegator = constructOutputDelegator();
        try {
            outputDelegator.multiReceive(RUBY.getCurrentContext(), events);
            assertEquals(events, fakeOutClass.getMultiReceiveArgs());
            assertEquals(EVENT_COUNT, ((RubyArray) fakeOutClass.getMultiReceiveArgs()).size());
        } catch (InterruptedException e) {
            fail("Multireceive error: " + e);
        }
    }

    @Test
    public void multiReceiveIncrementsEventCount() {
        OutputDelegatorExt outputDelegator = constructOutputDelegator();
        try {
            outputDelegator.multiReceive(RUBY.getCurrentContext(), events);
        } catch (InterruptedException e) {
            fail("Multireceive error: " + e);
        }

        assertEquals(EVENT_COUNT, getMetricLongValue("in"));
        assertEquals(EVENT_COUNT, getMetricLongValue("out"));
    }

    @Test
    public void multiReceiveRecordsDurationInMillis() {
        int delay = 100;
        long millis = 0;
        try {
            fakeOutClass.setMultiReceiveDelay(delay);
            OutputDelegatorExt outputDelegator = constructOutputDelegator();
            try {
                outputDelegator.multiReceive(RUBY.getCurrentContext(), events);
            } catch (InterruptedException e) {
                fail("Multireceive error: " + e);
            }
            millis = getMetricLongValue("duration_in_millis");
        } finally {
            fakeOutClass.setMultiReceiveDelay(0);
        }

        assertThat(millis).isCloseTo((long)delay, Percentage.withPercentage(10));
    }

    @Test
    public void registersOutputPlugin() {
        OutputDelegatorExt outputDelegator = constructOutputDelegator();
        outputDelegator.register(RUBY.getCurrentContext());

        assertEquals(1, fakeOutClass.getRegisterCallCount());
    }

    @Test
    public void closesOutputPlugin() {
        OutputDelegatorExt outputDelegator = constructOutputDelegator();
        outputDelegator.doClose(RUBY.getCurrentContext());

        assertEquals(1, fakeOutClass.getCloseCallCount());
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
            fakeOutClass.setOutStrategy(RUBY.getCurrentContext(), pair.symbol);
            OutputDelegatorExt outputDelegator = constructOutputDelegator();

            // test that output strategies are properly set
            IRubyObject outStrategy = outputDelegator.concurrency(RUBY.getCurrentContext());
            assertEquals(pair.symbol, outStrategy);

            // test that strategy classes are correctly instantiated
            IRubyObject strategyClass = outputDelegator.strategy(RUBY.getCurrentContext());
            assertThat(strategyClass).isInstanceOf(pair.klazz);

            // test that metrics are properly set on the instance
            assertEquals(outputDelegator.namespacedMetric(RUBY.getCurrentContext()), fakeOutClass.getMetricArgs());
        }
    }

    @Test
    public void outputStrategyMethodDelegationTests() {
        RubySymbol[] outputStrategies = new RubySymbol[]{
                RUBY.newSymbol("shared"),
                RUBY.newSymbol("single"),
                RUBY.newSymbol("legacy")
        };

        for (RubySymbol symbol : outputStrategies) {
            fakeOutClass = FakeOutClass.create();
            fakeOutClass.setOutStrategy(RUBY.getCurrentContext(), symbol);
            OutputDelegatorExt outputDelegator = constructOutputDelegator();
            outputDelegator.register(RUBY.getCurrentContext());
            assertEquals(1, fakeOutClass.getRegisterCallCount());

            outputDelegator.doClose(RUBY.getCurrentContext());
            assertEquals(1, fakeOutClass.getCloseCallCount());

            try {
                outputDelegator.multiReceive(RUBY.getCurrentContext(), RUBY.newArray(0));
                assertEquals(1, fakeOutClass.getMultiReceiveCallCount());
            } catch (InterruptedException e) {
                fail("multireceive error: " + e);
            }
        }

    }

    private static IRubyObject runRubyScript(String script) {
        IRubyObject m = RUBY.evalScriptlet(script);
        return m;
    }

    private OutputDelegatorExt constructOutputDelegator() {
        OutputDelegatorExt outputDelegator = (OutputDelegatorExt)
                new OutputDelegatorExt(RUBY, OUTPUT_DELEGATOR_CLASS).init(RUBY.getCurrentContext(), new IRubyObject[]{
                        fakeOutClass,
                        metric,
                        executionContext,
                        OutputStrategyExt.OutputStrategyRegistryExt.instance(RUBY.getCurrentContext(), null),
                        pluginArgs
                });
        return outputDelegator;
    }

    private RubyHash getMetricStore() {
        return getMetricStore(new String[]{"output", "foo", "events"});
    }

    private RubyHash getMetricStore(String[] path) {
        RubyHash metricStore = (RubyHash) metric.collector(RUBY.getCurrentContext())
                .callMethod(RUBY.getCurrentContext(), "snapshot_metric")
                .callMethod(RUBY.getCurrentContext(), "metric_store")
                .callMethod(RUBY.getCurrentContext(), "get_with_path", new IRubyObject[]{RUBY.newString("output/foo")});

        RubyHash rh = metricStore;
        for (String p : path) {
            rh = (RubyHash) rh.op_aref(RUBY.getCurrentContext(), RUBY.newSymbol(p));
        }
        return rh;
    }

    private String getMetricStringValue(RubyHash metricStore, String symbolName) {
        ConcreteJavaProxy counter = (ConcreteJavaProxy) metricStore.op_aref(RUBY.getCurrentContext(), RUBY.newSymbol(symbolName));
        RubyString value = (RubyString) counter.callMethod("value");
        return value.asJavaString();
    }

    private long getMetricLongValue(String symbolName) {
        return getMetricLongValue(getMetricStore(), symbolName);
    }

    private long getMetricLongValue(RubyHash metricStore, String symbolName) {
        ConcreteJavaProxy counter = (ConcreteJavaProxy) metricStore.op_aref(RUBY.getCurrentContext(), RUBY.newSymbol(symbolName));
        RubyFixnum count = (RubyFixnum) counter.callMethod("value");
        return count.getLongValue();
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
