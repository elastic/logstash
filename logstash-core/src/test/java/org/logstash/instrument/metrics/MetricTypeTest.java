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

import org.junit.Test;

import java.util.EnumSet;
import java.util.HashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;


/**
 * Unit tests for {@link MetricType}
 */
public class MetricTypeTest {

    /**
     * The {@link String} version of the {@link MetricType} should be considered as a public contract, and thus non-passive to change. Admittedly this test is a bit silly since it
     * just duplicates the code, but should cause a developer to think twice if they are changing the public contract.
     */
    @Test
    public void ensurePassivity(){
        Map<MetricType, String> nameMap = new HashMap<>(EnumSet.allOf(MetricType.class).size());
        nameMap.put(MetricType.COUNTER_LONG, "counter/long");
        nameMap.put(MetricType.COUNTER_DECIMAL, "counter/decimal");
        nameMap.put(MetricType.TIMER_LONG, "timer/long");
        nameMap.put(MetricType.GAUGE_TEXT, "gauge/text");
        nameMap.put(MetricType.GAUGE_BOOLEAN, "gauge/boolean");
        nameMap.put(MetricType.GAUGE_NUMBER, "gauge/number");
        nameMap.put(MetricType.GAUGE_UNKNOWN, "gauge/unknown");
        nameMap.put(MetricType.GAUGE_RUBYHASH, "gauge/rubyhash");
        nameMap.put(MetricType.GAUGE_RUBYTIMESTAMP, "gauge/rubytimestamp");
        nameMap.put(MetricType.FLOW_RATE, "flow/rate");

        //ensure we are testing all of the enumerations
        assertThat(EnumSet.allOf(MetricType.class).size()).isEqualTo(nameMap.size());

        nameMap.forEach((k,v) -> assertThat(k.asString()).isEqualTo(v));
        nameMap.forEach((k,v) -> assertThat(MetricType.fromString(v)).isEqualTo(k));
    }

}