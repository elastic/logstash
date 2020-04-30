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


package org.logstash.instrument.metrics.gauge;


import org.logstash.instrument.metrics.Metric;

/**
 * A {@link Metric} to set/get a value. A Gauge is useful for measuring a single value that may change over time, but does not carry any additional semantics beyond simply setting
 * and getting the value.
 * @param <G> The backing Java type for getting the gauge. For example, a text gauge should return a {@link String}
 * @param <S> The backing Java type for setting the gauge. For example, a text gauge is set with a {@link String}
 */
public interface GaugeMetric<G,S> extends Metric<G> {

    /**
     * Sets the value
     * @param value The value to set
     */
    void set(S value);


}
