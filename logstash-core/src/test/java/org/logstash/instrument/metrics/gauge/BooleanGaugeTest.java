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
 * Unit tests for {@link BooleanGauge}
 */
public class BooleanGaugeTest {
    @Test
    public void getValue() {
        BooleanGauge gauge = new BooleanGauge("bar", true);
        assertThat(gauge.getValue()).isTrue();
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_BOOLEAN);

        //Null initialize
        gauge = new BooleanGauge("bar");
        assertThat(gauge.getValue()).isNull();
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_BOOLEAN);
    }

    @Test
    public void set() {
        BooleanGauge gauge = new BooleanGauge("bar");
        assertThat(gauge.getValue()).isNull();
        gauge.set(true);
        assertThat(gauge.getValue()).isTrue();
        gauge.set(false);
        assertThat(gauge.getValue()).isFalse();
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_BOOLEAN);
        assertThat(gauge.getValue()).isFalse();
    }
}
