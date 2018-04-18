package org.logstash.ext;

import java.util.Collection;
import java.util.concurrent.TimeUnit;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.RubySymbol;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.internal.runtime.methods.DynamicMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.instrument.metrics.counter.LongCounter;

@JRubyClass(name = "WrappedWriteClient")
public final class JRubyWrappedWriteClientExt extends RubyObject {

    private static final RubySymbol PUSH_DURATION_KEY =
        RubyUtil.RUBY.newSymbol("queue_push_duration_in_millis");

    private static final RubySymbol IN_KEY = RubyUtil.RUBY.newSymbol("in");

    private DynamicMethod pushOne;
    private DynamicMethod pushBatch;

    private IRubyObject writeClient;

    private LongCounter eventsMetricsCounter;
    private LongCounter eventsMetricsTime;

    private LongCounter pipelineMetricsCounter;
    private LongCounter pipelineMetricsTime;

    private LongCounter pluginMetricsCounter;
    private LongCounter pluginMetricsTime;

    public JRubyWrappedWriteClientExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(name = "initialize", optional = 4)
    public IRubyObject ruby_initialize(final ThreadContext context, final IRubyObject[] args) {
        this.writeClient = args[0];
        final String pipelineId = args[1].asJavaString();
        final IRubyObject metric = args[2];
        // Synchronize on the metric since setting up new fields on it is not threadsafe
        synchronized (metric) {
            final IRubyObject pluginId = args[3];
            final IRubyObject eventsMetrics = getMetric(metric, "stats", "events");
            eventsMetricsCounter = LongCounter.fromRubyBase(eventsMetrics, IN_KEY);
            eventsMetricsTime = LongCounter.fromRubyBase(eventsMetrics, PUSH_DURATION_KEY);
            final IRubyObject pipelineMetrics =
                getMetric(metric, "stats", "pipelines", pipelineId, "events");
            pipelineMetricsCounter = LongCounter.fromRubyBase(pipelineMetrics, IN_KEY);
            pipelineMetricsTime = LongCounter.fromRubyBase(pipelineMetrics, PUSH_DURATION_KEY);
            final IRubyObject pluginMetrics = getMetric(
                metric, "stats", "pipelines", pipelineId, "plugins", "inputs",
                pluginId.asJavaString(), "events"
            );
            pluginMetricsCounter =
                LongCounter.fromRubyBase(pluginMetrics, context.runtime.newSymbol("out"));
            pluginMetricsTime = LongCounter.fromRubyBase(pluginMetrics, PUSH_DURATION_KEY);
            final RubyClass writerClass = writeClient.getMetaClass();
            pushOne = writerClass.searchMethod("push");
            pushBatch = writerClass.searchMethod("push_batch");
        }
        return this;
    }

    @JRubyMethod(name = {"push", "<<"}, required = 1)
    public IRubyObject push(final ThreadContext context, final IRubyObject event) {
        final long start = System.nanoTime();
        incrementCounters(1L);
        final IRubyObject res = pushOne.call(
            context, writeClient, RubyUtil.WRAPPED_WRITE_CLIENT_CLASS, "push", event
        );
        incrementTimers(start);
        return res;
    }

    @SuppressWarnings("unchecked")
    @JRubyMethod(name = "push_batch", required = 1)
    public IRubyObject pushBatch(final ThreadContext context, final IRubyObject batch) {
        final long start = System.nanoTime();
        incrementCounters((long) ((Collection<IRubyObject>) batch).size());
        final IRubyObject res = pushBatch.call(
            context, writeClient, RubyUtil.WRAPPED_WRITE_CLIENT_CLASS, "push_batch", batch
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
        final long increment = TimeUnit.NANOSECONDS.convert(
            System.nanoTime() - start, TimeUnit.MILLISECONDS
        );
        eventsMetricsTime.increment(increment);
        pipelineMetricsTime.increment(increment);
        pluginMetricsTime.increment(increment);
    }

    private static IRubyObject getMetric(final IRubyObject base, final String... keys) {
        return base.callMethod(
            RubyUtil.RUBY.getCurrentContext(), "namespace", toSymbolArray(keys)
        );
    }

    private static IRubyObject toSymbolArray(final String... strings) {
        final IRubyObject[] res = new IRubyObject[strings.length];
        for (int i = 0; i < strings.length; ++i) {
            res[i] = RubyUtil.RUBY.newSymbol(strings[i]);
        }
        return RubyUtil.RUBY.newArray(res);
    }
}
