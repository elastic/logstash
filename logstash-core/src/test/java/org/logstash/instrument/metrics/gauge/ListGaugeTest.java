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
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Test;
import org.logstash.RubyUtil;
import org.logstash.instrument.metrics.MetricType;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link TextGauge}
 */
public class ListGaugeTest {
    @Test
    public void getSetStrings() {
        ListGauge gauge = new ListGauge("bar");
        gauge.set(List.of("pipeline_name1", "pipeline_name2"));
        assertThat(gauge.getValue().toString()).isEqualTo("[pipeline_name1, pipeline_name2]");
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_LIST);
    }

    @Test
    public void getSetNull() {
        ListGauge gauge = new ListGauge("bar");
        gauge.set(null);
        assertThat(gauge.getValue()).isNull();
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_LIST);
    }

    @Test
    public void getSetListOfNull() {
        List<Object> nullList = new ArrayList<>(Collections.nCopies(2, null));
        ListGauge gauge = new ListGauge("bar");
        gauge.set(nullList);
        assertThat(gauge.getValue().toString()).isEqualTo("[null, null]");
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_LIST);
    }

    @Test
    public void getSetHash() {
        IRubyObject[] args = {RubyUtil.RUBY.newString("k"), RubyUtil.RUBY.newString("v")};
        RubyHash rubyHash = RubyHash.newHash(RubyUtil.RUBY, args[0], args[1]);

        ListGauge gauge = new ListGauge("bar");
        gauge.set(List.of(rubyHash));
        // JRuby 10 changed hash formatting to include spaces around =>
        assertThat(gauge.getValue().toString()).isEqualTo("[{\"k\" => \"v\"}]");
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_LIST);
    }

    @Test
    public void getSetNumber() {
        ListGauge gauge = new ListGauge("bar");
        gauge.set(List.of(123, 456.7));
        assertThat(gauge.getValue().toString()).isEqualTo("[123, 456.7]");
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_LIST);
    }
}
