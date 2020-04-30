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

import org.jruby.RubyHash;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.logstash.instrument.metrics.MetricType;
import org.mockito.Mock;
import org.mockito.runners.MockitoJUnitRunner;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.ThrowableAssert.catchThrowable;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link RubyHashGauge}
 */
@SuppressWarnings("deprecation")
@RunWith(MockitoJUnitRunner.class)
public class RubyHashGaugeTest {

    @Mock
    RubyHash rubyHash;

    private static final String RUBY_HASH_AS_STRING = "{}";

    @Before
    public void _setup() {
        //hacky workaround using the toString method to avoid mocking the Ruby runtime
        when(rubyHash.toString()).thenReturn(RUBY_HASH_AS_STRING);
    }

    @Test
    public void getValue() {
        RubyHashGauge gauge = new RubyHashGauge("bar", rubyHash);
        assertThat(gauge.getValue().toString()).isEqualTo(RUBY_HASH_AS_STRING);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYHASH);

        //Null initialize
        final RubyHashGauge gauge2 = new RubyHashGauge("bar");
        Throwable thrown = catchThrowable(() -> {
            gauge2.getValue().toString();
        });
        assertThat(thrown).isInstanceOf(NullPointerException.class);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYHASH);
    }

    @Test
    public void set() {
        RubyHashGauge gauge = new RubyHashGauge("bar");
        gauge.set(rubyHash);
        assertThat(gauge.getValue().toString()).isEqualTo(RUBY_HASH_AS_STRING);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYHASH);
    }

}
