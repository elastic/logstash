package org.logstash.config.ir.compiler;

import com.google.common.annotations.VisibleForTesting;
import java.util.Collection;
import java.util.concurrent.TimeUnit;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.execution.WorkerLoop;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.MetricKeys;
import org.logstash.instrument.metrics.counter.LongCounter;

@JRubyClass(name = "JavaFilterDelegator")
public final class FilterDelegatorExt extends RubyObject {

    private static final long serialVersionUID = 1L;

    private IRubyObject filterClass;

    private IRubyObject filter;

    private IRubyObject metricEvents;

    private RubyString id;

    private LongCounter eventMetricOut;

    private LongCounter eventMetricIn;

    private LongCounter eventMetricTime;

    private boolean flushes;

    @JRubyMethod
    public IRubyObject initialize(final ThreadContext context, final IRubyObject filter,
        final IRubyObject id) {
        this.id = (RubyString) id;
        this.filter = filter;
        this.filterClass = filter.getSingletonClass().getRealClass();
        final AbstractNamespacedMetricExt namespacedMetric =
            (AbstractNamespacedMetricExt) filter.callMethod(context, "metric");
        metricEvents = namespacedMetric.namespace(context, MetricKeys.EVENTS_KEY);
        eventMetricOut = LongCounter.fromRubyBase(metricEvents, MetricKeys.OUT_KEY);
        eventMetricIn = LongCounter.fromRubyBase(metricEvents, MetricKeys.IN_KEY);
        eventMetricTime = LongCounter.fromRubyBase(
            metricEvents, MetricKeys.DURATION_IN_MILLIS_KEY
        );
        namespacedMetric.gauge(context, MetricKeys.NAME_KEY, configName(context));
        flushes = filter.respondsTo("flush");
        return this;
    }

    @VisibleForTesting
    public FilterDelegatorExt initForTesting(final IRubyObject filter) {
        eventMetricOut = LongCounter.DUMMY_COUNTER;
        eventMetricIn = LongCounter.DUMMY_COUNTER;
        eventMetricTime = LongCounter.DUMMY_COUNTER;
        this.filter = filter;
        flushes = filter.respondsTo("flush");
        return this;
    }

    public FilterDelegatorExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    public IRubyObject register(final ThreadContext context) {
        return filter.callMethod(context, "register");
    }

    @JRubyMethod
    public IRubyObject close(final ThreadContext context) {
        return filter.callMethod(context, "close");
    }

    @JRubyMethod(name = "do_close")
    public IRubyObject doClose(final ThreadContext context) {
        return filter.callMethod(context, "do_close");
    }

    @JRubyMethod(name = "do_stop")
    public IRubyObject doStop(final ThreadContext context) {
        return filter.callMethod(context, "do_stop");
    }

    @JRubyMethod(name = "reloadable?")
    public IRubyObject isReloadable(final ThreadContext context) {
        return filter.callMethod(context, "reloadable?");
    }

    @JRubyMethod(name = "threadsafe?")
    public IRubyObject concurrency(final ThreadContext context) {
        return filter.callMethod(context, "threadsafe?");
    }

    @JRubyMethod(name = "config_name")
    public IRubyObject configName(final ThreadContext context) {
        return filterClass.callMethod(context, "config_name");
    }

    @JRubyMethod(name = "id")
    public IRubyObject getId() {
        return id;
    }

    @SuppressWarnings("unchecked")
    public RubyArray multiFilter(final RubyArray batch) {
        eventMetricIn.increment((long) batch.size());
        final long start = System.nanoTime();
        final RubyArray result = (RubyArray) filter.callMethod(
            WorkerLoop.THREAD_CONTEXT.get(), "multi_filter", batch
        );
        eventMetricTime.increment(
            TimeUnit.MILLISECONDS.convert(System.nanoTime() - start, TimeUnit.NANOSECONDS)
        );
        int count = 0;
        for (final JrubyEventExtLibrary.RubyEvent event : (Collection<JrubyEventExtLibrary.RubyEvent>) result) {
            if (!event.getEvent().isCancelled()) {
                ++count;
            }
        }
        eventMetricOut.increment((long) count);
        return result;
    }

    public RubyArray flush(final RubyHash options) {
        final ThreadContext context = WorkerLoop.THREAD_CONTEXT.get();
        final IRubyObject newEvents = filter.callMethod(context, "flush", options);
        final RubyArray result;
        if (newEvents.isNil()) {
            result = RubyArray.newEmptyArray(context.runtime);
        } else {
            result = (RubyArray) newEvents;
            eventMetricOut.increment((long) result.size());
        }
        return result;
    }

    public boolean hasFlush() {
        return flushes;
    }

    public boolean periodicFlush() {
        return filter.callMethod(RubyUtil.RUBY.getCurrentContext(), "periodic_flush").isTrue();
    }
}
