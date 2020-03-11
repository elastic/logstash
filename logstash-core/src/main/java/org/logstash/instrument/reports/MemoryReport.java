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


package org.logstash.instrument.reports;

import org.logstash.instrument.monitors.MemoryMonitor;

import java.util.HashMap;
import java.util.Map;

public class MemoryReport {

    private static final String NON_HEAP = "non_heap";
    private static final String HEAP = "heap";

    /**
     * Build a report with current Memory information
     * @return Returns a Map containing information about the
     *         current state of the Java memory pools
     *
     */
    public static Map<String, Map<String, Map<String, Object>>> generate() {
        MemoryMonitor.Report report = generateReport(MemoryMonitor.Type.All);
        Map<String, Map<String, Map<String, Object>>> container = new HashMap<>();
        container.put(HEAP, report.getHeap());
        container.put(NON_HEAP, report.getNonHeap());
        return container;
    }

    private static MemoryMonitor.Report generateReport(MemoryMonitor.Type type) {
        return MemoryMonitor.detect(type);
    }
}
