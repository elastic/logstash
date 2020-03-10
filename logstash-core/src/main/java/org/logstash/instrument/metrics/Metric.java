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


package org.logstash.instrument.metrics;

/**
 * Top level contract for metrics within Logstash.
 *
 * @param <T> The underlying type for this metric. For example {@link Long} for Counter, or {@link String} for Gauge.
 * @since 6.0
 */
public interface Metric<T> {

    /**
     * This metric's name. May be used for display purposes.
     *
     * @return The name of this metric.
     */
    String getName();

    /**
     * This should be equal to #getValue, exists for passivity with legacy Ruby code. Java consumers should use #getValue().
     *
     * @return This metric value
     * @deprecated
     */
    @Deprecated
    default T get() {
        return getValue();
    }

    /**
     * The enumerated Metric Type. This is a semantic type <i>(not Java type)</i> that can be useful to help identify the type of Metric. For example "counter/long".
     *
     * @return The {@link MetricType} that this metric represents.
     */
    MetricType getType();

    /**
     * Retrieves the value associated with this metric
     *
     * @return This metric value
     */
    T getValue();

    /**
     * This may be equal to the #toString method, exists for passivity with legacy Ruby code. Java consumers should use #toString
     *
     * @return A description of this Metric that can be used for logging.
     * @deprecated
     */
    @Deprecated
    default String inspect() {
        return toString();
    }

    /**
     * This should be equal to {@link MetricType#asString()}, exists for passivity with legacy Ruby code. Java consumers should use #getType().
     *
     * @return The {@link String} version of the {@link MetricType}
     * @deprecated
     */
    @Deprecated
    default String type() {
        return getType().asString();
    }

}
