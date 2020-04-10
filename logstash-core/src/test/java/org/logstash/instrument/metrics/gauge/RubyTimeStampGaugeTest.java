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
import org.junit.runner.RunWith;
import org.logstash.RubyUtil;
import org.logstash.Timestamp;
import org.logstash.ext.JrubyTimestampExtLibrary;
import org.logstash.instrument.metrics.MetricType;
import org.mockito.runners.MockitoJUnitRunner;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link RubyTimeStampGauge}
 */
@SuppressWarnings("deprecation")
@RunWith(MockitoJUnitRunner.class)
public class RubyTimeStampGaugeTest {

    private static final Timestamp TIMESTAMP = new Timestamp();

    private static final JrubyTimestampExtLibrary.RubyTimestamp RUBY_TIMESTAMP =
        JrubyTimestampExtLibrary.RubyTimestamp.newRubyTimestamp(
            RubyUtil.RUBY, TIMESTAMP
        );

    @Test
    public void getValue() {
        RubyTimeStampGauge gauge = new RubyTimeStampGauge("bar", RUBY_TIMESTAMP);
        assertThat(gauge.getValue()).isEqualTo(RUBY_TIMESTAMP.getTimestamp());
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYTIMESTAMP);

        //Null initialize
        gauge = new RubyTimeStampGauge("bar");
        assertThat(gauge.getValue()).isNull();
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYTIMESTAMP);
    }

    @Test
    public void set() {
        RubyTimeStampGauge gauge = new RubyTimeStampGauge("bar");
        gauge.set(RUBY_TIMESTAMP);
        assertThat(gauge.getValue()).isEqualTo(RUBY_TIMESTAMP.getTimestamp());
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYTIMESTAMP);
    }
}
