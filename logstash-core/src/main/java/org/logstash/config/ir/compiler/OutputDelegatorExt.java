package org.logstash.config.ir.compiler;

import com.google.common.annotations.VisibleForTesting;
import java.util.concurrent.TimeUnit;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.execution.WorkerLoop;
import org.logstash.instrument.metrics.MetricKeys;
import org.logstash.instrument.metrics.counter.LongCounter;

@JRubyClass(name = "OutputDelegator")
public final class OutputDelegatorExt extends RubyObject {

    private static final long serialVersionUID = 1L;

    private IRubyObject outputClass;

    private OutputStrategyExt.AbstractOutputStrategyExt strategy;

    private IRubyObject metric;

    private IRubyObject namespacedMetric;

    private IRubyObject metricEvents;

    private RubyString id;

    private LongCounter eventMetricOut;

    private LongCounter eventMetricIn;

    private LongCounter eventMetricTime;

    @JRubyMethod(name = "initialize", optional = 5)
    public IRubyObject init(final ThreadContext context, final IRubyObject[] arguments) {
        outputClass = arguments[0];
        metric = arguments[1];
        final RubyHash args = (RubyHash) arguments[4];
        id = (RubyString) args.op_aref(context, RubyString.newString(context.runtime, "id"));
        namespacedMetric = metric.callMethod(context, "namespace", id.intern19());
        metricEvents = namespacedMetric.callMethod(
            context, "namespace", RubySymbol.newSymbol(context.runtime, "events")
        );
        namespacedMetric.callMethod(
            context, "gauge",
            new IRubyObject[]{
                RubySymbol.newSymbol(context.runtime, "name"), configName(context)
            }
        );
        eventMetricOut = LongCounter.fromRubyBase(metricEvents, MetricKeys.OUT_KEY);
        eventMetricIn = LongCounter.fromRubyBase(metricEvents, MetricKeys.IN_KEY);
        eventMetricTime = LongCounter.fromRubyBase(
            metricEvents, MetricKeys.DURATION_IN_MILLIS_KEY
        );
        strategy = (OutputStrategyExt.AbstractOutputStrategyExt) (
            (OutputStrategyExt.OutputStrategyRegistryExt) arguments[3])
            .classFor(context, concurrency(context)).newInstance(
                context,
                new IRubyObject[]{outputClass, namespacedMetric, arguments[2], args},
                Block.NULL_BLOCK
            );
        return this;
    }

    @VisibleForTesting
    public OutputDelegatorExt initForTesting(
        final OutputStrategyExt.AbstractOutputStrategyExt strategy
    ) {
        eventMetricOut = LongCounter.DUMMY_COUNTER;
        eventMetricIn = LongCounter.DUMMY_COUNTER;
        eventMetricTime = LongCounter.DUMMY_COUNTER;
        this.strategy = strategy;
        return this;
    }

    public OutputDelegatorExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    public IRubyObject register(final ThreadContext context) {
        return strategy.register(context);
    }

    @JRubyMethod(name = "do_close")
    public IRubyObject doClose(final ThreadContext context) {
        return strategy.doClose(context);
    }

    @JRubyMethod(name = "reloadable?")
    public IRubyObject isReloadable(final ThreadContext context) {
        return outputClass.callMethod(context, "reloadable?");
    }

    @JRubyMethod
    public IRubyObject concurrency(final ThreadContext context) {
        return outputClass.callMethod(context, "concurrency");
    }

    @JRubyMethod(name = "config_name")
    public IRubyObject configName(final ThreadContext context) {
        return outputClass.callMethod(context, "config_name");
    }

    @JRubyMethod
    public IRubyObject id(final ThreadContext context) {
        return id;
    }

    @JRubyMethod
    public IRubyObject metric(final ThreadContext context) {
        return metric;
    }

    @JRubyMethod(name = "namespaced_metric")
    public IRubyObject namespacedMetric(final ThreadContext context) {
        return namespacedMetric;
    }

    @JRubyMethod(name = "metric_events")
    public IRubyObject metricEvents(final ThreadContext context) {
        return metricEvents;
    }

    @JRubyMethod
    public IRubyObject strategy(final ThreadContext context) {
        return strategy;
    }

    public IRubyObject multiReceive(final RubyArray events) {
        try {
            return multiReceive(WorkerLoop.THREAD_CONTEXT.get(), events);
        } catch (final InterruptedException ex) {
            throw new IllegalStateException(ex);
        }
    }

    @JRubyMethod(name = "multi_receive")
    public IRubyObject multiReceive(final ThreadContext context, final IRubyObject events)
        throws InterruptedException {
        final RubyArray batch = (RubyArray) events;
        final int count = batch.size();
        eventMetricIn.increment((long) count);
        final long start = System.nanoTime();
        strategy.multiReceive(context, batch);
        eventMetricTime.increment(
            TimeUnit.MILLISECONDS.convert(System.nanoTime() - start, TimeUnit.NANOSECONDS)
        );
        eventMetricOut.increment((long) count);
        return this;
    }
}
