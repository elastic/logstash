package org.logstash.instrument.metrics;

import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.instrument.metrics.timer.TestTimerMetricFactory;

import java.util.function.Function;

import static org.logstash.RubyUtil.METRIC_CLASS;

/**
 * This {@code MetricExtFactory} can be used from any tests that
 * inherit from {@link org.logstash.config.ir.RubyEnvTestCase}, which ensures
 * that the ruby-parts of Logstash are loaded and/or available.
 */
public class MetricExtFactory {
    private final TestClock testClock;

    public MetricExtFactory(final TestClock testClock) {
        this.testClock = testClock;
    }

    private static final RubyClass COLLECTOR_CLASS = (RubyClass) RubyUtil.RUBY.evalScriptlet(
            "require 'logstash/instrument/collector'\n" +
                    "::LogStash::Instrument::Collector");

    private static final RubyClass INTERCEPTOR_MODULE_CLASS = (RubyClass) RubyUtil.RUBY.evalScriptlet(
            String.join("\n",
                    "Class.new(Module) do",
                    "  def initialize(intercept_type, metric_factory)",
                    "    define_method(:initialize_metric) do |type, namespaces_path, key|",
                    "      return super(type, namespaces_path, key) unless type == intercept_type",
                    "      metric_factory.create(key)",
                    "    end",
                    "  end",
                    "end"
            )
    );

    public static MetricExt newMetricExtFromTestClock(final TestClock testClock) {
        return new MetricExtFactory(testClock).newRoot();
    }

    public MetricExt newRoot() {
        final IRubyObject metricCollector = COLLECTOR_CLASS.callMethod("new");

        rubyExtend(metricCollector, metricFactoryInterceptor("uptime", (new TestUptimeMetricFactory(testClock::nanoTime))::newUptimeMetric));
        rubyExtend(metricCollector, metricFactoryInterceptor("timer", (new TestTimerMetricFactory(testClock::nanoTime))::newTimerMetric));

        return (MetricExt)METRIC_CLASS.newInstance(RubyUtil.RUBY.getCurrentContext(), metricCollector, Block.NULL_BLOCK);
    }

    private RubyModule metricFactoryInterceptor(final String type, final Function<String,?> javaMetricFactory) {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();

        final IRubyObject interceptType = context.runtime.newSymbol(type);
        final IRubyObject metricFactory = JavaUtil.convertJavaToUsableRubyObject(context.runtime, MetricFactory.of(javaMetricFactory));
        final IRubyObject interceptorModule = INTERCEPTOR_MODULE_CLASS.newInstance(context, interceptType, metricFactory, Block.NULL_BLOCK);

        return (RubyModule) interceptorModule;
    }

    private static void rubyExtend(final IRubyObject base, final RubyModule module) {
        base.callMethod(base.getRuntime().getCurrentContext(), "extend", module);
    }

    @FunctionalInterface
    interface MetricFactory {
        IRubyObject create(final IRubyObject key);

        static MetricFactory of(final Function<String,?> javaMetricFactory) {
            return key -> JavaUtil.convertJavaToUsableRubyObject(RubyUtil.RUBY, javaMetricFactory.apply(key.asJavaString()));
        }
    }
}
