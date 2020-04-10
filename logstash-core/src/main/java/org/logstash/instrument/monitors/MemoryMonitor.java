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
import java.lang.management.MemoryPoolMXBean;
import java.lang.management.MemoryType;
import java.lang.management.MemoryUsage;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public final class MemoryMonitor {

    private MemoryMonitor() {
        //Utility Class
    }

    public enum Type {
        All, Heap, NonHeap
    }

    public static class Report {

        private static final String USAGE_INIT = "usage.init";
        private static final String USAGE_COMMITTED = "usage.committed";
        private static final String USAGE_USED = "usage.used";
        private static final String USAGE_MAX = "usage.max";
        private static final String PEAK_INIT = "peak.init";
        private static final String PEAK_COMMITTED = "peak.committed";
        private static final String PEAK_USED = "peak.used";
        private static final String PEAK_MAX = "peak.max";

        private Map<String, Map<String, Object>> heapMap = new HashMap<>();
        private Map<String, Map<String, Object>> nonHeapMap = new HashMap<>();

        private Report() {}

        public Map<String, Map<String, Object>> getHeap() {
            return heapMap;
        }

        public Map<String, Map<String, Object>> getNonHeap() {
            return nonHeapMap;
        }

        void addMemoryBeanInfo(MemoryPoolMXBean bean){
            Map<String, Map<String, Object>> memoryMap = bean.getType().equals(MemoryType.HEAP) ? heapMap : nonHeapMap;
            Map<String, Object> beanMap = memoryMap.computeIfAbsent(bean.getName(), k -> new HashMap<>());
            addUsage(beanMap, bean.getUsage());
            addPeak(beanMap, bean.getPeakUsage());
        }

        private static void addUsage(Map<String, Object> map, MemoryUsage usage){
            map.put(USAGE_INIT, usage.getInit());
            map.put(USAGE_COMMITTED, usage.getCommitted());
            map.put(USAGE_USED, usage.getUsed());
            map.put(USAGE_MAX, usage.getMax());
        }

        private static void addPeak(Map<String, Object> map, MemoryUsage peak){
            map.put(PEAK_INIT, peak.getInit());
            map.put(PEAK_COMMITTED, peak.getCommitted());
            map.put(PEAK_USED, peak.getUsed());
            map.put(PEAK_MAX, peak.getMax());
        }
     }

     public static Report detect(Type selectType){
        List<MemoryPoolMXBean> beans = ManagementFactory.getMemoryPoolMXBeans();
        Report report = new Report();

        beans.stream().filter(bean -> (selectType.equals(Type.All))
                                       || !filterPool(bean.getType(), selectType))
                      .forEach(report::addMemoryBeanInfo);
        return report;
    }

    private static boolean filterPool(MemoryType type, Type selectType) {
       return ((selectType.equals(Type.NonHeap) && type.equals(MemoryType.HEAP))
               || (selectType.equals(Type.Heap) && type.equals(MemoryType.NON_HEAP)));
    }
}
