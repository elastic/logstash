package org.logstash.instrument.metrics.timer;

import org.jruby.RubySymbol;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.Metric;
import org.logstash.instrument.metrics.MetricType;

/**
 * The {@code TimerMetric} is a logstash-internal extension of its public
 * {@link co.elastic.logstash.api.TimerMetric} counterpart that provides read-
 * and introspection-access via {@code Metric<Long>}.
 */
public interface TimerMetric extends co.elastic.logstash.api.TimerMetric, Metric<Long> {
    Long getValue();

    @Override
    default MetricType getType() {
        return MetricType.TIMER_LONG;
    }

    static TimerMetric create(final String name) {
        return TimerMetricFactory.INSTANCE.create(name);
    }

    static TimerMetric fromRubyBase(final AbstractNamespacedMetricExt metric,
                                    final RubySymbol key) {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        final IRubyObject timer = metric.timer(context, key);
        final TimerMetric javaTimer;
        if (TimerMetric.class.isAssignableFrom(timer.getJavaClass())) {
            javaTimer = timer.toJava(TimerMetric.class);
        } else {
            javaTimer = NullTimerMetric.getInstance();
        }
        return javaTimer;
    }
}