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


package org.logstash.instrument.metrics.counter;

import org.logstash.instrument.metrics.Metric;

/**
 * A {@link Metric} to count things. A counter can only increment, and there are no guarantees of durability of current value between JVM restarts.
 * @param <T> The underlying {@link Number} type that can be incremented. Care should be taken to which {@link Number} is used to back the counter, since some {@link Number}
 *           types may not be appropriate for a monotonic increasing series.
 */
public interface CounterMetric<T extends Number> extends Metric<T> {

    /**
     * Helper method that increments by 1
     */
    void increment();

    /**
     * Increments the counter by the value specified. <i>The caller should be careful to avoid incrementing by values so large as to overflow the underlying type.</i>
     * @param by The value which to increment by. Can not be negative.
     */
    void increment(T by) ;
}
