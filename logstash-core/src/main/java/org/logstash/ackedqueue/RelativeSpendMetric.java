package org.logstash.ackedqueue;

import co.elastic.logstash.api.TimerMetric;
import co.elastic.logstash.api.UserMetric;
import org.logstash.instrument.metrics.MetricType;
import org.logstash.instrument.metrics.timer.NullTimerMetric;

interface RelativeSpendMetric extends UserMetric<Double>, org.logstash.instrument.metrics.Metric<Double>, TimerMetric {

    default MetricType getType() {
        return MetricType.USER;
    }

    Provider<RelativeSpendMetric> PROVIDER = new Provider<>(RelativeSpendMetric.class, new RelativeSpendMetric() {
        @Override
        public <T, E extends Throwable> T time(ExceptionalSupplier<T, E> exceptionalSupplier) throws E {
            return NullTimerMetric.getInstance().time(exceptionalSupplier);
        }

        @Override
        public void reportUntrackedMillis(long untrackedMillis) {
            // no-op
        }

        @Override
        public Double getValue() {
            return 0.0;
        }

        @Override
        public String getName() {
            return "NULL";
        }
    });
}
