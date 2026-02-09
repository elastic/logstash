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


package org.logstash.plugins;

import co.elastic.logstash.api.CounterMetric;
import co.elastic.logstash.api.Metric;
import co.elastic.logstash.api.NamespacedMetric;
import co.elastic.logstash.api.UserMetric;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyObject;
import org.jruby.RubySymbol;
import org.jruby.api.Create;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.Rubyfier;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.NullMetricExt;
import org.logstash.instrument.metrics.NullNamespacedMetricExt;
import org.logstash.instrument.metrics.timer.TimerMetric;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.function.Supplier;
import java.util.stream.Stream;

/**
 * Wraps a {@link AbstractNamespacedMetricExt} that represents a nested namespace and adds
 * metrics and other namespaces to it.
 */
public class NamespacedMetricImpl implements NamespacedMetric {

    private static final NamespacedMetric NULL_METRIC;
    static {
        final Ruby rubyRuntime = RubyUtil.RUBY;
        final ThreadContext context = rubyRuntime.getCurrentContext();
        final NullMetricExt nullMetricExt = NullMetricExt.create();
        final AbstractNamespacedMetricExt namespacedMetricExt = NullNamespacedMetricExt.create(nullMetricExt, (RubyArray) Create.newArray(context));

        NULL_METRIC = new NamespacedMetricImpl(context, namespacedMetricExt){
            @Override
            public NamespacedMetric namespace(String... key) {
                return this;
            }
        };
    }

    public static NamespacedMetric getNullMetric() {
        return NULL_METRIC;
    }

    private final ThreadContext threadContext;

    private final AbstractNamespacedMetricExt metrics;

    public NamespacedMetricImpl(final ThreadContext threadContext, final AbstractNamespacedMetricExt metrics) {
        this.threadContext = threadContext;
        this.metrics = metrics;
    }

    @Override
    public void gauge(final String key, final Object value) {
        this.metrics.gauge(this.threadContext, this.getSymbol(key), Rubyfier.deep(this.threadContext.getRuntime(), value));
    }

    @Override
    public CounterMetric counter(final String metric) {
        return new CounterMetricImpl(this.threadContext, this.metrics, metric);
    }

    @Override
    public co.elastic.logstash.api.TimerMetric timer(final String metric) {
        return TimerMetric.fromRubyBase(metrics, threadContext.getRuntime().newString(metric).intern(threadContext));
    }

    @Override
    public <USER_METRIC extends UserMetric<?>> USER_METRIC register(String metric, UserMetric.Factory<USER_METRIC> userMetricFactory) {
        USER_METRIC userMetric = org.logstash.instrument.metrics.UserMetric.fromRubyBase(metrics, threadContext.runtime.newSymbol(metric), userMetricFactory);

        return Objects.requireNonNullElseGet(userMetric, userMetricFactory::nullImplementation);
    }

    @Override
    public NamespacedMetric namespace(final String... key) {
        final IRubyObject[] rubyfiedKeys = Stream.of(key)
            .map(this::getSymbol)
            .toArray(IRubyObject[]::new);

        return new NamespacedMetricImpl(
            this.threadContext,
            this.metrics.namespace(this.threadContext, RubyArray.newArray(this.threadContext.getRuntime(), rubyfiedKeys))
        );
    }

    @Override
    public void increment(final String key) {
        this.metrics.increment(this.threadContext, new IRubyObject[] { this.getSymbol(key) });
    }

    @Override
    public void increment(final String key, final int amount) {
        this.metrics.increment(this.threadContext, new IRubyObject[] {
            this.getSymbol(key),
            this.convert(amount)
        });
    }

    @Override
    public <T> T time(final String key, final Supplier<T> callable) {
        return timer(key).time(callable::get);
    }

    @Override
    public void reportTime(final String key, final long duration) {
        timer(key).reportUntrackedMillis(duration);
    }

    @Override
    public String[] namespaceName() {
        final List<String> names = new ArrayList<>();

        for (final Object o : this.metrics.namespaceName(this.threadContext)) {
            if (o instanceof RubyObject) {
                names.add(((RubyObject) o).to_s(this.threadContext).toString());
            }
        }

        return names.toArray(new String[0]);
    }

    @Override
    public Metric root() {
        return new RootMetricImpl(this.threadContext, this.metrics.root(this.threadContext));
    }

    private RubySymbol getSymbol(final String s) {
        return this.threadContext.getRuntime().newString(s).intern(this.threadContext);
    }

    private IRubyObject convert(final Object o) {
        return Rubyfier.deep(this.threadContext.getRuntime(), o);
    }
}
