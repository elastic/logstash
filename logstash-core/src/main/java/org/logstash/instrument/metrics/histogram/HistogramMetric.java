package org.logstash.instrument.metrics.histogram;

import co.elastic.logstash.api.UserMetric;
import org.HdrHistogram.Histogram;
import org.logstash.instrument.metrics.MetricType;

public interface HistogramMetric extends UserMetric<Histogram>, org.logstash.instrument.metrics.Metric<Histogram> {
//     Histogram getValue();

     /**
      * Records a value in the histogram. The value must be non-negative.
       *
       * @param value the value to record
       * @throws IllegalArgumentException if the value is negative
      * */
     void recordValue(long value);

     @Override
     default MetricType getType() {
         return MetricType.USER;
     }

     Provider<HistogramMetric> PROVIDER = new Provider<>(HistogramMetric.class, new HistogramMetric() {
         @Override
         public void recordValue(long value) {
             // no op
         }

         @Override
         public Histogram getValue() {
             // small empty histogram to avoid null checks in consumers
             return new Histogram(1);
         }

         @Override
         public String getName() {
             return "NULL";
         }
     });
}
