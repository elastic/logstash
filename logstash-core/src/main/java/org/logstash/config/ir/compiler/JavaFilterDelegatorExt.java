package org.logstash.config.ir.compiler;

import co.elastic.logstash.api.Event;
import co.elastic.logstash.api.Filter;
import co.elastic.logstash.api.FilterMatchListener;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.anno.JRubyClass;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;
import java.util.stream.Collectors;

@JRubyClass(name = "JavaFilterDelegator")
public class JavaFilterDelegatorExt extends AbstractFilterDelegatorExt {

    private static final long serialVersionUID = 1L;

    private static final RubySymbol CONCURRENCY = RubyUtil.RUBY.newSymbol("java");

    private RubyString configName;

    private Filter filter;

    private FilterMatchListener filterMatchListener;

    public JavaFilterDelegatorExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    public static JavaFilterDelegatorExt create(final String configName, final String id,
                                                final AbstractNamespacedMetricExt metric,
                                                final Filter filter, final Map<String, Object> pluginArgs) {
        final JavaFilterDelegatorExt instance =
                new JavaFilterDelegatorExt(RubyUtil.RUBY, RubyUtil.JAVA_FILTER_DELEGATOR_CLASS);
        instance.configName = RubyUtil.RUBY.newString(configName);
        AbstractNamespacedMetricExt scopedMetric =
                metric.namespace(RubyUtil.RUBY.getCurrentContext(), RubyUtil.RUBY.newSymbol(filter.getId()));
        instance.initMetrics(id, scopedMetric);
        instance.filter = filter;
        instance.initializeFilterMatchListener(pluginArgs);
        return instance;
    }

    @SuppressWarnings({"unchecked","rawtypes"})
    @Override
    protected RubyArray doMultiFilter(final RubyArray batch) {
        List<Event> inputEvents = (List<Event>) batch.stream()
                .map(x -> ((JrubyEventExtLibrary.RubyEvent) x).getEvent())
                .collect(Collectors.toList());
        Collection<Event> outputEvents = filter.filter(inputEvents, filterMatchListener);
        RubyArray newBatch = RubyArray.newArray(RubyUtil.RUBY, outputEvents.size());
        for (Event outputEvent : outputEvents) {
            newBatch.add(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, (org.logstash.Event)outputEvent));
        }
        return newBatch;
    }

    @Override
    protected void doRegister(ThreadContext context) {
    }

    @Override
    protected IRubyObject doFlush(final ThreadContext context, final RubyHash options) {
        if (filter.requiresFlush()) {
            Collection<Event> outputEvents = filter.flush(filterMatchListener);
            @SuppressWarnings("rawtypes") RubyArray newBatch = RubyArray.newArray(RubyUtil.RUBY, outputEvents.size());
            for (Event outputEvent : outputEvents) {
                newBatch.add(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, (org.logstash.Event)outputEvent));
            }
            return newBatch;
        }

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
        return filter.requiresFlush();
    }

    @Override
    protected boolean getPeriodicFlush() {
        return filter.requiresPeriodicFlush();
    }

    @SuppressWarnings("unchecked")
    private void initializeFilterMatchListener(Map<String, Object> pluginArgs) {
        List<Consumer<Event>> filterActions = new ArrayList<>();
        for (Map.Entry<String, Object> entry : pluginArgs.entrySet()) {
            Consumer<Event> filterAction =
                    CommonActions.getFilterAction(entry);
            if (filterAction != null) {
                filterActions.add(filterAction);
            }
        }

        if (filterActions.size() == 0) {
            this.filterMatchListener = e -> {
            };
        } else {
            this.filterMatchListener = new DecoratingFilterMatchListener(filterActions);
        }
    }

    static class DecoratingFilterMatchListener implements FilterMatchListener {

        private final List<Consumer<Event>> actions;

        DecoratingFilterMatchListener(List<Consumer<Event>> actions) {
            this.actions = actions;
        }

        @Override
        public void filterMatched(Event e) {
            for (Consumer<Event> action : actions) {
                action.accept(e);
            }
        }
    }
}
