package org.logstash.config.ir.compiler;

import javax.annotation.concurrent.NotThreadSafe;
import org.assertj.core.data.Percentage;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.java.proxies.ConcreteJavaProxy;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Before;
import org.junit.Test;
import org.logstash.Event;
import org.logstash.config.ir.RubyEnvTestCase;
import org.logstash.execution.ExecutionContextExt;
import org.logstash.instrument.metrics.NamespacedMetricExt;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.Assert.assertEquals;
import static org.logstash.RubyUtil.EXECUTION_CONTEXT_CLASS;
import static org.logstash.RubyUtil.NAMESPACED_METRIC_CLASS;
import static org.logstash.RubyUtil.RUBY;
import static org.logstash.RubyUtil.RUBY_OUTPUT_DELEGATOR_CLASS;

@SuppressWarnings("rawtypes")
@NotThreadSafe
public class OutputDelegatorTest extends RubyEnvTestCase {

    private NamespacedMetricExt metric;
    private ExecutionContextExt executionContext;
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
        events = RUBY.newArray(EVENT_COUNT);
        for (int k = 0; k < EVENT_COUNT; k++) {
            events.add(k, new Event());
        }
        final ThreadContext context = RUBY.getCurrentContext();
        RubyArray namespaces = RubyArray.newArray(RUBY, 1);
        namespaces.add(0, RubySymbol.newSymbol(RUBY, "output"));
        IRubyObject metricWithCollector =
                runRubyScript("require \"logstash/instrument/collector\"\n" +
                        "metricWithCollector = LogStash::Instrument::Metric.new(LogStash::Instrument::Collector.new)");

        metric = new NamespacedMetricExt(RUBY, NAMESPACED_METRIC_CLASS)
                .initialize(context, metricWithCollector, namespaces);
        executionContext = new ExecutionContextExt(RUBY, EXECUTION_CONTEXT_CLASS);
        pluginArgs = RubyHash.newHash(RUBY);
        pluginArgs.put("id", "foo");
        pluginArgs.put("arg1", "val1");
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

    private static IRubyObject runRubyScript(String script) {
        IRubyObject m = RUBY.evalScriptlet(script);
        return m;
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
