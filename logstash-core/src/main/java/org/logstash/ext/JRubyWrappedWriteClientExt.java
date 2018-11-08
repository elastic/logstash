package org.logstash.ext;

import java.util.Collection;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.RubySymbol;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.execution.queue.QueueWriter;
import org.logstash.instrument.metrics.AbstractMetricExt;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.MetricKeys;
import org.logstash.instrument.metrics.counter.LongCounter;

@JRubyClass(name = "WrappedWriteClient")
public final class JRubyWrappedWriteClientExt extends RubyObject implements QueueWriter {

    private static final RubySymbol PUSH_DURATION_KEY =
        RubyUtil.RUBY.newSymbol("queue_push_duration_in_millis");

    private JRubyAbstractQueueWriteClientExt writeClient;

    private LongCounter eventsMetricsCounter;
    private LongCounter eventsMetricsTime;

    private LongCounter pipelineMetricsCounter;
    private LongCounter pipelineMetricsTime;

    private LongCounter pluginMetricsCounter;
    private LongCounter pluginMetricsTime;

    public JRubyWrappedWriteClientExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(required = 4)
    public JRubyWrappedWriteClientExt initialize(final ThreadContext context,
        final IRubyObject[] args) {
        return initialize((JRubyAbstractQueueWriteClientExt) args[0], args[1].asJavaString(),
            (AbstractMetricExt) args[2], args[3]);
    }

    public JRubyWrappedWriteClientExt initialize(
        final JRubyAbstractQueueWriteClientExt queueWriteClientExt, final String pipelineId,
        final AbstractMetricExt metric, final IRubyObject pluginId) {
        this.writeClient = queueWriteClientExt;
        // Synchronize on the metric since setting up new fields on it is not threadsafe
        synchronized (metric) {
            final AbstractNamespacedMetricExt eventsMetrics =
                getMetric(metric, "stats", "events");
            eventsMetricsCounter = LongCounter.fromRubyBase(eventsMetrics, MetricKeys.IN_KEY);
            eventsMetricsTime = LongCounter.fromRubyBase(eventsMetrics, PUSH_DURATION_KEY);
            final AbstractNamespacedMetricExt pipelineMetrics =
                getMetric(metric, "stats", "pipelines", pipelineId, "events");
            pipelineMetricsCounter = LongCounter.fromRubyBase(pipelineMetrics, MetricKeys.IN_KEY);
            pipelineMetricsTime = LongCounter.fromRubyBase(pipelineMetrics, PUSH_DURATION_KEY);
            final AbstractNamespacedMetricExt pluginMetrics = getMetric(
                metric, "stats", "pipelines", pipelineId, "plugins", "inputs",
                pluginId.asJavaString(), "events"
            );
            pluginMetricsCounter =
                LongCounter.fromRubyBase(pluginMetrics, MetricKeys.OUT_KEY);
            pluginMetricsTime = LongCounter.fromRubyBase(pluginMetrics, PUSH_DURATION_KEY);
        }
        return this;
    }

    @JRubyMethod(name = {"push", "<<"}, required = 1)
    public IRubyObject push(final ThreadContext context, final IRubyObject event)
        throws InterruptedException {
        final long start = System.nanoTime();
        incrementCounters(1L);
        final IRubyObject res = writeClient.doPush(context, (JrubyEventExtLibrary.RubyEvent) event);
        incrementTimers(start);
        return res;
    }

    @SuppressWarnings("unchecked")
    @JRubyMethod(name = "push_batch", required = 1)
    public IRubyObject pushBatch(final ThreadContext context, final IRubyObject batch)
        throws InterruptedException {
        final long start = System.nanoTime();
        incrementCounters((long) ((Collection<IRubyObject>) batch).size());
        final IRubyObject res = writeClient.doPushBatch(
            context, (Collection<JrubyEventExtLibrary.RubyEvent>) batch
        );
        incrementTimers(start);
        return res;
    }

    /**
     * @param context Ruby {@link ThreadContext}
     * @return Empty {@link RubyArray}
     * @deprecated This method exists for backwards compatibility only, it does not do anything but
     * return an empty {@link RubyArray}.
     */
    @Deprecated
    @JRubyMethod(name = "get_new_batch")
    public IRubyObject newBatch(final ThreadContext context) {
        return context.runtime.newArray();
    }

    private void incrementCounters(final long count) {
        eventsMetricsCounter.increment(count);
        pipelineMetricsCounter.increment(count);
        pluginMetricsCounter.increment(count);
    }

    private void incrementTimers(final long start) {
        final long increment = TimeUnit.MILLISECONDS.convert(
            System.nanoTime() - start, TimeUnit.NANOSECONDS
        );
        eventsMetricsTime.increment(increment);
        pipelineMetricsTime.increment(increment);
        pluginMetricsTime.increment(increment);
    }

    private static AbstractNamespacedMetricExt getMetric(final AbstractMetricExt base,
        final String... keys) {
        return base.namespace(RubyUtil.RUBY.getCurrentContext(), toSymbolArray(keys));
    }

    private static IRubyObject toSymbolArray(final String... strings) {
        final IRubyObject[] res = new IRubyObject[strings.length];
        for (int i = 0; i < strings.length; ++i) {
            res[i] = RubyUtil.RUBY.newSymbol(strings[i]);
        }
        return RubyUtil.RUBY.newArray(res);
    }

    @Override
    public void push(Map<String, Object> event) {
        final long start = System.nanoTime();
        incrementCounters(1L);
        writeClient.push(event);
        incrementTimers(start);
    }
}
