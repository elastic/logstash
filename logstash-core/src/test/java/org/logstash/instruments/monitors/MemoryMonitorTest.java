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
import org.logstash.instrument.monitors.MemoryMonitor;

import java.util.Map;

import static org.hamcrest.CoreMatchers.hasItem;
import static org.hamcrest.CoreMatchers.hasItems;
import static org.hamcrest.CoreMatchers.notNullValue;
import static org.hamcrest.MatcherAssert.assertThat;


public class MemoryMonitorTest {

    @Test
    public void testEachHeapSpaceRepresented() {
        Map<String, Map<String, Object>> heap = MemoryMonitor.detect(MemoryMonitor.Type.All).getHeap();
        assertThat(heap, notNullValue());
        assertThat(heap.keySet(), hasItems("G1 Old Gen", "G1 Survivor Space", "G1 Eden Space"));
    }

    @Test
    public void testAllStatsAreAvailableForHeap(){
        testAllStatsAreAvailable(MemoryMonitor.detect(MemoryMonitor.Type.All).getHeap());
    }

    @Test
    public void testAllStatsAreAvailableForNonHeap(){
        testAllStatsAreAvailable(MemoryMonitor.detect(MemoryMonitor.Type.All).getNonHeap());
    }

    private void testAllStatsAreAvailable(Map<String, Map<String, Object>> stats){
        String[] types = {"usage", "peak"};
        String[] subtypes = {"used", "max", "committed", "init"};
        for (Map<String, Object> spaceMap: stats.values()){
            for (String type : types) {
                for (String subtype : subtypes){
                    String key = String.format("%s.%s", type, subtype);
                    assertThat(key + " is missing", spaceMap.keySet(), hasItem(key));
                }
            }
        }
    }
}
