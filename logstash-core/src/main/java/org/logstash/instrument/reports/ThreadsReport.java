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

import org.logstash.instrument.monitors.HotThreadsMonitor;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * A ThreadsReport object used to hold the hot threads information
 */
public class ThreadsReport {


    /**
     * Generate a report with current Thread information
     * @param options Map of options to narrow this method functionality:
     *                Keys: ordered_by - can be "cpu", "wait" or "block"
     *                      stacktrace_size - max depth of stack trace
     * @return A Map containing hot threads information
     */
    public static List<Map<String, Object>> generate(Map<String, String> options) {
        List<HotThreadsMonitor.ThreadReport> reports = HotThreadsMonitor.detect(options);
        return reports
                .stream()
                .map(HotThreadsMonitor.ThreadReport::toMap)
                .collect(Collectors.toList());
    }


    /**
     * Generate a report with current Thread information
     * @return A Map containing the hot threads information
     */
    public static List<Map<String, Object>> generate() {
        Map<String, String> options = new HashMap<>();
        options.put("order_by", "cpu");
        return generate(options);
    }
}
