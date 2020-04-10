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

import static org.assertj.core.api.Assertions.assertThat;


/**
 * Unit tests for {@link NumberGauge}
 */
public class NumberGaugeTest {

    @Test
    public void getValue() {
        NumberGauge gauge = new NumberGauge("bar", 99l);
        assertThat(gauge.getValue()).isEqualTo(99l);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_NUMBER);
        //other number type
        gauge.set(98.00);
        assertThat(gauge.getValue()).isEqualTo(98.00);

        //Null
        gauge = new NumberGauge("bar");
        assertThat(gauge.getValue()).isNull();
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_NUMBER);
    }

    @Test
    public void set() {
        NumberGauge gauge = new NumberGauge("bar");
        assertThat(gauge.getValue()).isNull();
        gauge.set(123l);
        assertThat(gauge.getValue()).isEqualTo(123l);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_NUMBER);
    }
}