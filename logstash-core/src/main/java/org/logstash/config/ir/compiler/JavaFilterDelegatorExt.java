package org.logstash.config.ir.compiler;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.anno.JRubyClass;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.Event;
import org.logstash.RubyUtil;
import co.elastic.logstash.api.v0.Filter;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;

import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

@JRubyClass(name = "JavaFilterDelegator")
public class JavaFilterDelegatorExt extends AbstractFilterDelegatorExt {

    private static final long serialVersionUID = 1L;

    private static final RubySymbol CONCURRENCY = RubyUtil.RUBY.newSymbol("java");

    private RubyString configName;

    private Filter filter;

    public JavaFilterDelegatorExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    public static JavaFilterDelegatorExt create(final String configName, final String id,
                                                final AbstractNamespacedMetricExt metric,
                                                final Filter filter) {
        final JavaFilterDelegatorExt instance =
                new JavaFilterDelegatorExt(RubyUtil.RUBY, RubyUtil.JAVA_FILTER_DELEGATOR_CLASS);
        instance.configName = RubyUtil.RUBY.newString(configName);
        instance.initMetrics(id, metric);
        instance.filter = filter;
        return instance;
    }

    @SuppressWarnings("unchecked")
    @Override
    protected RubyArray doMultiFilter(final RubyArray batch) {
        List<Event> inputEvents = (List<Event>)batch.stream()
                .map(x -> ((JrubyEventExtLibrary.RubyEvent)x).getEvent())
                .collect(Collectors.toList());
        Collection<Event> outputEvents = filter.filter(inputEvents);
        RubyArray newBatch = RubyArray.newArray(RubyUtil.RUBY, outputEvents.size());
        for (Event outputEvent : outputEvents) {
            newBatch.add(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, outputEvent));
        }
        return newBatch;
    }

    @Override
    protected void doRegister(ThreadContext context) {}

    @Override
    protected IRubyObject doFlush(final ThreadContext context, final RubyHash options) {
        // add flush() to Java filter API?
        return context.nil;
    }

    @Override
    protected IRubyObject closeImpl(final ThreadContext context) {
        return context.nil;
    }

    @Override
    protected IRubyObject doCloseImpl(final ThreadContext context) {
        return context.nil;
    }

    @Override
    protected IRubyObject doStopImpl(final ThreadContext context) {
        return context.nil;
    }

    @Override
    protected IRubyObject reloadable(final ThreadContext context) {
        return context.tru;
    }

    @Override
    protected IRubyObject getConcurrency(final ThreadContext context) {
        return CONCURRENCY;
    }

    @Override
    protected IRubyObject getConfigName(final ThreadContext context) {
        return configName;
    }

    @Override
    protected boolean getHasFlush() {
        return false;
    }

    @Override
    protected boolean getPeriodicFlush() {
        return false;
    }
}
