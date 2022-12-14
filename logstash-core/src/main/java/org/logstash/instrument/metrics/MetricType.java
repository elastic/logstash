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


import java.util.EnumSet;

/**
 * A semantic means of defining the type of metric. Also serves as the list of supported metrics.
 */
public enum MetricType {

    /**
     * A counter backed by a {@link Long} type
     */
    COUNTER_LONG("counter/long"),

    /**
     * A counter backed by a {@link Number} type that includes decimal precision
     */
    COUNTER_DECIMAL("counter/decimal"),

    /**
     * A timer backed by a {@link Long} type
     */
    TIMER_LONG("timer/long"),

    /**
     * A gauge backed by a {@link String} type
     */
    GAUGE_TEXT("gauge/text"),
    /**
     * A gauge backed by a {@link Boolean} type
     */
    GAUGE_BOOLEAN("gauge/boolean"),
    /**
     * A gauge backed by a {@link Number} type
     */
    GAUGE_NUMBER("gauge/number"),
     /**
     * A gauge backed by a {@link Object} type.
     */
    GAUGE_UNKNOWN("gauge/unknown"),
    /**
     * A gauge backed by a {@link org.jruby.RubyHash} type. Note - Java consumers should not use this, exist for legacy Ruby code.
     */
    GAUGE_RUBYHASH("gauge/rubyhash"),
    /**
     * A gauge backed by a {@link org.logstash.ext.JrubyTimestampExtLibrary.RubyTimestamp} type. Note - Java consumers should not use this, exist for legacy Ruby code.
     */
    GAUGE_RUBYTIMESTAMP("gauge/rubytimestamp"),

    /**
     * A flow-rate {@link FlowMetric}, instantiated with one or more backing {@link Metric}{@code <Number>}.
     */
    FLOW_RATE("flow/rate"),
    ;

    private final String type;

    MetricType(final String type) {
        this.type = type;
    }

    /**
     * Finds the {@link MetricType} enumeration that matches the provided {@link String}
     *
     * @param s The input string
     * @return The {@link MetricType} that matches the input, else null.
     */
    public static MetricType fromString(String s) {
        return EnumSet.allOf(MetricType.class).stream().filter(e -> e.asString().equalsIgnoreCase(s)).findFirst().orElse(null);
    }

    /**
     * Retrieve the {@link String} representation of this MetricType.
     *
     * @return the {@link String} representation
     */
    public String asString() {
        return type;
    }

}
