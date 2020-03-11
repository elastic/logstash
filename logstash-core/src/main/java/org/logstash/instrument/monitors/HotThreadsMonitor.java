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
import java.lang.management.ThreadInfo;
import java.lang.management.ThreadMXBean;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * Hot threads monitoring class. This class pulls information out of the JVM #
 * provided beans and lest the different consumers query it.
 */
public final class HotThreadsMonitor {

    private static final String ORDERED_BY = "ordered_by";
    private static final String STACKTRACE_SIZE = "stacktrace_size";
    private static final Logger logger = LogManager.getLogger(HotThreadsMonitor.class);

    private HotThreadsMonitor() {
        //Utility Class
    }

    /**
     * Placeholder for a given thread report
     */
    public static class ThreadReport {

        private static final String CPU_TIME = "cpu.time";
        private static final String BLOCKED_COUNT = "blocked.count";
        private static final String BLOCKED_TIME = "blocked.time";
        private static final String WAITED_COUNT = "waited.count";
        private static final String WAITED_TIME = "waited.time";
        private static final String THREAD_NAME = "thread.name";
        private static final String THREAD_STATE = "thread.state";
        private static final String THREAD_STACKTRACE = "thread.stacktrace";
        private static final String THREAD_ID = "thread.id";

        private Map<String, Object> map = new HashMap<>();

        ThreadReport(ThreadInfo info, long cpuTime) {
            map.put(CPU_TIME, cpuTime);
            map.put(BLOCKED_COUNT, info.getBlockedCount());
            map.put(BLOCKED_TIME, info.getBlockedTime());
            map.put(WAITED_COUNT, info.getWaitedCount());
            map.put(WAITED_TIME, info.getWaitedTime());
            map.put(THREAD_NAME, info.getThreadName());
            map.put(THREAD_ID, info.getThreadId());
            map.put(THREAD_STATE, info.getThreadState().name().toLowerCase());
            map.put(THREAD_STACKTRACE, stackTraceAsString(info.getStackTrace()));
        }

        private static List<String> stackTraceAsString(StackTraceElement[] elements) {
            return Arrays.stream(elements)
                            .map(StackTraceElement::toString)
                            .collect(Collectors.toList());
        }

        public Map<String, Object> toMap() {
            return map;
        }

        public String getThreadName() {
            return (String) map.get(THREAD_NAME);
        }

        public long getThreadId() {
            return (long) map.get(THREAD_ID);
        }

        @Override
        public String toString() {
            StringBuilder sb = new StringBuilder();
            int i = 0;
            for (Map.Entry<String, Object> mapEntry: map.entrySet()) {
                if (i > 0) {
                    sb.append(",");
                }
                sb.append(String.format("%s,%s", mapEntry.getKey(), mapEntry.getValue()));
                i++;
            }
            return sb.toString();
        }

        Long getWaitedTime() {
            return (Long)map.get(WAITED_TIME);
        }

        Long getBlockedTime() {
            return (Long)map.get(BLOCKED_TIME);
        }

        Long getCpuTime() {
            return (Long) map.get(CPU_TIME);
        }
    }

    private static final Collection<String>
        VALID_ORDER_BY = new HashSet<>(Arrays.asList("cpu", "wait", "block"));

    /**
     * Return the current hot threads information as provided by the JVM
     *
     * @return A list of ThreadReport including all selected threads
     */
    public static List<ThreadReport> detect() {
        Map<String, String> options = new HashMap<>();
        options.put(ORDERED_BY, "cpu");
        return detect(options);
    }

    /**
     * Return the current hot threads information as provided by the JVM
     *
     * @param options Map of options to narrow this method functionality:
     *                Keys: ordered_by - can be "cpu", "wait" or "block"
     *                      stacktrace_size - max depth of stack trace
     * @return A list of ThreadReport including all selected threads
     */
    public static List<ThreadReport> detect(Map<String, String> options) {
        String type = "cpu";
        if (options.containsKey(ORDERED_BY)) {
            type = options.get(ORDERED_BY);
            if (!isValidSortOrder(type))
                throw new IllegalArgumentException("Invalid sort order");
        }

        Integer threadInfoMaxDepth = 50;
        if (options.containsKey(STACKTRACE_SIZE)) {
            threadInfoMaxDepth = Integer.valueOf(options.get(STACKTRACE_SIZE));
        }

        ThreadMXBean threadMXBean = ManagementFactory.getThreadMXBean();
        enableCpuTime(threadMXBean);

        Map<Long, ThreadReport> reports = new HashMap<>();

        for (long threadId : threadMXBean.getAllThreadIds()) {
            if (Thread.currentThread().getId() == threadId) {
                continue;
            }

            long cpuTime = threadMXBean.getThreadCpuTime(threadId);
            if (cpuTime == -1) {
                continue;
            }
            ThreadInfo info = threadMXBean.getThreadInfo(threadId, threadInfoMaxDepth);
            if (info != null) {
                /*
                 * Thread ID must exist and be alive, otherwise the threads just
                 * died in the meanwhile and could be ignored.
                 */
                reports.put(threadId, new ThreadReport(info, cpuTime));
            }
        }
        return sort(new ArrayList<>(reports.values()), type);
     }

    private static List<ThreadReport> sort(List<ThreadReport> reports, final String type) {
        reports.sort(comparatorForOrderType(type));
        return reports;
    }

    private static Comparator<ThreadReport> comparatorForOrderType(final String type){
        if ("block".equals(type)){
            return Comparator.comparingLong(ThreadReport::getBlockedTime).reversed();
        } else if ("wait".equals(type)) {
            return Comparator.comparingLong(ThreadReport::getWaitedTime).reversed();
        } else{
            return Comparator.comparingLong(ThreadReport::getCpuTime).reversed();
        }
    }

    private static boolean isValidSortOrder(String type) {
        return VALID_ORDER_BY.contains(type.toLowerCase());
    }

    private static void enableCpuTime(ThreadMXBean threadMXBean) {
        try {
            if (threadMXBean.isThreadCpuTimeSupported()) {
                if (!threadMXBean.isThreadCpuTimeEnabled()) {
                    threadMXBean.setThreadCpuTimeEnabled(true);
                }
            }
        } catch (SecurityException ex) {
            // This should not happen - the security manager should not be enabled.
            logger.debug("Cannot enable Thread Cpu Time", ex);
        }
    }
}
