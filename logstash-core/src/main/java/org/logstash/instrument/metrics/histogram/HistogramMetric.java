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

package org.logstash.instrument.metrics.histogram;

import co.elastic.logstash.api.UserMetric;
import org.HdrHistogram.Histogram;
import org.logstash.instrument.metrics.MetricType;

public interface HistogramMetric extends UserMetric<Histogram>, org.logstash.instrument.metrics.Metric<Histogram> {

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
