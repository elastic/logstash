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

import org.junit.Test;
import org.logstash.instrument.metrics.MetricType;

import java.net.URI;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link UnknownGauge}
 */
@SuppressWarnings("deprecation")
public class UnknownGaugeTest {

    @Test
    public void getValue() {
        UnknownGauge gauge = new UnknownGauge("bar", URI.create("baz"));
        assertThat(gauge.getValue()).isEqualTo(URI.create("baz"));
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_UNKNOWN);

        //Null initialize
        gauge = new UnknownGauge("bar");
        assertThat(gauge.getValue()).isNull();
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_UNKNOWN);
    }

    @Test
    public void set() {
        UnknownGauge gauge = new UnknownGauge("bar");
        gauge.set(URI.create("baz"));
        assertThat(gauge.getValue()).isEqualTo(URI.create("baz"));
        gauge.set(URI.create("fizzbuzz"));
        assertThat(gauge.getValue()).isEqualTo(URI.create("fizzbuzz"));
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_UNKNOWN);
    }
}
