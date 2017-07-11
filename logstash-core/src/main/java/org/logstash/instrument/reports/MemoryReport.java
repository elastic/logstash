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

