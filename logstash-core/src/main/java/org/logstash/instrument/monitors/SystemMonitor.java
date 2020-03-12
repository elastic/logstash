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


package org.logstash.instrument.monitors;

import java.lang.management.ManagementFactory;
import java.lang.management.OperatingSystemMXBean;
import java.util.HashMap;
import java.util.Map;

/**
 * System information as returned by the different JVM's MxBeans
 */
public class SystemMonitor {

    public static class Report {

        private static final String OS_NAME = "os.name";
        private static final String OS_VERSION = "os.version";
        private static final String OS_ARCH = "os.arch";
        private static final String SYSTEM_AVAILABLE_PROCESSORS = "system.available_processors";
        private static final String SYSTEM_LOAD_AVERAGE = "system.load_average";
        private Map<String, Object> map = new HashMap<>();

        Report(OperatingSystemMXBean osBean) {
            map.put(OS_NAME, osBean.getName());
            map.put(OS_VERSION, osBean.getVersion());
            map.put(OS_ARCH, osBean.getArch());
            map.put(SYSTEM_AVAILABLE_PROCESSORS, osBean.getAvailableProcessors());
            map.put(SYSTEM_LOAD_AVERAGE, osBean.getSystemLoadAverage());
        }

        public Map<String, Object> toMap() {
            return map;
        }
    }

    public static Report detect() {
        return new Report(ManagementFactory.getOperatingSystemMXBean());
    }
}
