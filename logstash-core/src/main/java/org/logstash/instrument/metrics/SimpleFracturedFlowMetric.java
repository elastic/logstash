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

import java.util.Collections;
import java.util.Map;
import java.util.Objects;
import java.util.function.LongSupplier;

/**
 * A class to apply a fraction on top of simple flow metrics.
 */
public class SimpleFracturedFlowMetric extends SimpleFlowMetric {

    private final Number fraction;

    /**
     * A constructor to create SimpleFracturedFlowMetric.
     * @param name name of the metric
     * @param numeratorMetric numerator
     * @param denominatorMetric denominator
     * @param fraction fraction value
     */
    public SimpleFracturedFlowMetric(final String name,
                                     final Metric<? extends Number> numeratorMetric,
                                     final Metric<? extends Number> denominatorMetric,
                                     final Number fraction) {
        super(name, numeratorMetric, denominatorMetric);
        this.fraction = fraction;
    }

    SimpleFracturedFlowMetric(final LongSupplier nanoTimeSupplier,
                              final String name,
                              final Metric<? extends Number> numeratorMetric,
                              final Metric<? extends Number> denominatorMetric,
                              final Number fraction) {
        super(nanoTimeSupplier, name, numeratorMetric, denominatorMetric);
        this.fraction = fraction;
    }

    @Override
    public Map<String, Double> getValue() {
        Map<String, Double> rates = super.getValue();

        // falling back to super class rates if fraction is N.A or ZERO
        if (Objects.isNull(this.fraction) || MetricsUtil.isValueUndefined(this.fraction.doubleValue())) {
            return rates;
        }

        Map<String, Double> fracturedRates = MetricsUtil.applyFraction(rates, this.fraction);
        return Collections.unmodifiableMap(fracturedRates);
    }
}