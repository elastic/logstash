/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


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

    private RubyString configName;

    private transient Filter filter;

    private transient FilterMatchListener filterMatchListener;

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
            final Ruby runtime = context.runtime;
            @SuppressWarnings("rawtypes") RubyArray newBatch = RubyArray.newArray(runtime, outputEvents.size());
            for (Event outputEvent : outputEvents) {
                newBatch.add(JrubyEventExtLibrary.RubyEvent.newRubyEvent(runtime, (org.logstash.Event)outputEvent));
            }
            return newBatch;
        }

        return context.nil;
    }

    @Override
    protected IRubyObject closeImpl(final ThreadContext context) {
        filter.close();
        return context.nil;
    }

    @Override
    protected IRubyObject doCloseImpl(final ThreadContext context) {
        filter.close();
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
    protected IRubyObject isThreadsafe(final ThreadContext context) {
        return context.tru;
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
