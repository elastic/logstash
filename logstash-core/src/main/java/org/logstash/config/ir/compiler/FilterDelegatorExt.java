package org.logstash.config.ir.compiler;

import com.google.common.annotations.VisibleForTesting;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.internal.runtime.methods.DynamicMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.execution.WorkerLoop;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.counter.LongCounter;

@JRubyClass(name = "FilterDelegator")
public final class FilterDelegatorExt extends AbstractFilterDelegatorExt {

    private static final long serialVersionUID = 1L;

    private static final String FILTER_METHOD_NAME = "multi_filter";

    private RubyClass filterClass;

    private IRubyObject filter;

    private DynamicMethod filterMethod;

    private boolean flushes;

    @JRubyMethod(name="initialize")
    public IRubyObject initialize(final ThreadContext context, final IRubyObject filter, final IRubyObject id) {
        this.id = (RubyString) id;
        this.filter = filter;
        filterClass = filter.getSingletonClass().getRealClass();
        filterMethod = filterClass.searchMethod(FILTER_METHOD_NAME);
        final AbstractNamespacedMetricExt namespacedMetric = (AbstractNamespacedMetricExt) filter.callMethod(context, "metric");
        initMetrics(this.id.asJavaString(), namespacedMetric);
        flushes = filter.respondsTo("flush");
        return this;
    }

    @VisibleForTesting
    public FilterDelegatorExt initForTesting(final IRubyObject filter) {
        eventMetricOut = LongCounter.DUMMY_COUNTER;
        eventMetricIn = LongCounter.DUMMY_COUNTER;
        eventMetricTime = LongCounter.DUMMY_COUNTER;
        this.filter = filter;
        filterMethod = filter.getMetaClass().searchMethod(FILTER_METHOD_NAME);
        flushes = filter.respondsTo("flush");
        return this;
    }

    public FilterDelegatorExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @Override
    protected void doRegister(final ThreadContext context) {
        filter.callMethod(context, "register");
    }

    @Override
    protected IRubyObject closeImpl(final ThreadContext context) {
        return filter.callMethod(context, "close");
    }

    @Override
    protected IRubyObject doCloseImpl(final ThreadContext context) {
        return filter.callMethod(context, "do_close");
    }

    @Override
    protected IRubyObject doStopImpl(final ThreadContext context) {
        return filter.callMethod(context, "do_stop");
    }

    @Override
    protected IRubyObject reloadable(final ThreadContext context) {
        return filter.callMethod(context, "reloadable?");
    }

    @Override
    protected IRubyObject getConcurrency(final ThreadContext context) {
        return filter.callMethod(context, "threadsafe?");
    }

    @Override
    protected IRubyObject getConfigName(final ThreadContext context) {
        return filterClass.callMethod(context, "config_name");
    }

    @Override
    protected RubyArray doMultiFilter(final RubyArray batch) {
        return (RubyArray) filterMethod.call(
                WorkerLoop.THREAD_CONTEXT.get(), filter, filterClass, FILTER_METHOD_NAME, batch);
    }

    @Override
    protected IRubyObject doFlush(final ThreadContext context, final RubyHash options) {
        return filter.callMethod(context, "flush", options);
    }

    @Override
    protected boolean getHasFlush() {
        return flushes;
    }

    @Override
    protected boolean getPeriodicFlush() {
        return filter.callMethod(RubyUtil.RUBY.getCurrentContext(), "periodic_flush").isTrue();
    }
}
