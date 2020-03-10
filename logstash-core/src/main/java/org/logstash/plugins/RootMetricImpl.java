package org.logstash.plugins;

import co.elastic.logstash.api.Metric;
import co.elastic.logstash.api.NamespacedMetric;
import org.jruby.RubyArray;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.instrument.metrics.AbstractMetricExt;

import java.util.stream.Stream;

/**
 * Wraps a {@link AbstractMetricExt} and represents a "root metric" that must be
 * namespaced in order to write metrics to.
 */
public class RootMetricImpl implements Metric {
    private final ThreadContext threadContext;
    private final AbstractMetricExt metrics;

    public RootMetricImpl(final ThreadContext threadContext, final AbstractMetricExt root) {
        this.threadContext = threadContext;
        this.metrics = root;
    }

    @Override
    public NamespacedMetric namespace(final String... key) {
        final IRubyObject[] rubyfiedKeys = Stream.of(key)
            .map(this.threadContext.getRuntime()::newSymbol)
            .toArray(IRubyObject[]::new);

        return new NamespacedMetricImpl(
            this.threadContext,
            this.metrics.namespace(this.threadContext, RubyArray.newArray(this.threadContext.getRuntime(), rubyfiedKeys))
        );
    }
}
