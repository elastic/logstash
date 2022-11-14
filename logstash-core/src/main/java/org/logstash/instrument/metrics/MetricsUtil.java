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

import com.google.common.annotations.VisibleForTesting;

import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * A class to help metric classes to separate math calculation parts.
 */
public class MetricsUtil {

    public static final Double ZERO = 0.0d;

    public static final Double HUNDRED = 100.0d;

    /**
     * Applies fraction value on top of provided map values.
     * @param rates metric rates map
     * @param fraction fraction value
     * @return a map where values are fractured based on input map
     */
    public static Map<String, Double> applyFraction(Map<String, Double> rates, Number fraction) {
        return rates.entrySet()
                .stream()
                .collect(Collectors.toMap(Map.Entry::getKey,
                        e -> toPercentage(fraction, multiply(fraction.doubleValue(), e.getValue()))));
    }

    /**
     * Decides if given value can be used to proceed calculation.
     * @param value a value
     * @return true if value is valid, false otherwise
     */
    public static boolean isValueUndefined(Double value) {
        return Objects.isNull(value) || value.isInfinite() || value.isNaN() || ZERO.equals(value);
    }

    private static Double multiply(Double nominator, Double denominator) {
        if (isValueUndefined(nominator) || isValueUndefined(denominator)) {
            return ZERO;
        }
        return nominator * denominator;
    }

    @VisibleForTesting
    static Double toPercentage(Number fraction, Double number) {
        double percentage = number / HUNDRED;
        double roundedPercentage = Math.round(percentage * 100) / HUNDRED;
        return Math.min(roundedPercentage, fraction.doubleValue() * HUNDRED);
    }
}