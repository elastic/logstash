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


package org.logstash.instruments.monitors;

import org.junit.Test;
import org.logstash.instrument.monitors.SystemMonitor;

import java.util.Map;

import static org.hamcrest.CoreMatchers.*;
import static org.hamcrest.MatcherAssert.assertThat;


public class SystemMonitorTest {

    @Test
    public void systemMonitorTest(){
        Map<String, Object> map = SystemMonitor.detect().toMap();
        assertThat("os.name is missing", map.get("os.name"), allOf(notNullValue(), instanceOf(String.class)));
        if (!((String) map.get("os.name")).startsWith("Windows")) {
            assertThat("system.load_average is missing", (Double) map.get("system.load_average") > 0, is(true));
        }
        assertThat("system.available_processors is missing ", ((Integer)map.get("system.available_processors")) > 0, is(true));
        assertThat("os.version is missing", map.get("os.version"), allOf(notNullValue(), instanceOf(String.class)));
        assertThat("os.arch is missing", map.get("os.arch"), allOf(notNullValue(), instanceOf(String.class)));
    }
}
