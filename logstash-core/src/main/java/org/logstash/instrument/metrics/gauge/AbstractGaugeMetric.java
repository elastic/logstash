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

import org.logstash.instrument.metrics.AbstractMetric;

/**
 * Abstract {@link GaugeMetric} to hold the gauge value and handle the dirty state. Simplifies the contract by requiring the both the getter and setter to be the same type.
 * @param <T> The type to set and get this gauge.
 */
public abstract class AbstractGaugeMetric<T> extends AbstractMetric<T> implements GaugeMetric<T,T>{

    private volatile T value;

    /**
     * Constructor
     *
     * @param name The name of this metric. This value may be used for display purposes.
     */
    protected AbstractGaugeMetric(String name) {
        super(name);
    }

    /**
     * Constructor
     *
     * @param name         The name of this metric. This value may be used for display purposes.
     * @param initialValue The initial value for this {@link GaugeMetric}, may be null
     */
    public AbstractGaugeMetric(String name, T initialValue) {
        super(name);
        this.value = initialValue;
    }


    @Override
    public T getValue() {
        return value;
    }


    @Override
    public void set(T value) {
        this.value = value;
    }

}
