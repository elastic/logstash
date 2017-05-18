package org.logstash.instrument.reports;

import org.jruby.*;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.instrument.monitors.MemoryMonitor;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MemoryReport {

    private static final String NON_HEAP = "non_heap";
    private static final String HEAP = "heap";

    /**
     * Build a report with current Memory information
     * @return
     */
    public static Map<String, Map<String, Map<String, Object>>> generate() {
        MemoryMonitor.Report report = generateReport(MemoryMonitor.Type.All);
        Map<String, Map<String, Map<String, Object>>> container = new HashMap<>();
        container.put(HEAP, report.getHeap());
        container.put(NON_HEAP, report.getNonHeap());
        return container;
    }

    private static MemoryMonitor.Report generateReport(MemoryMonitor.Type type) {
        return new MemoryMonitor().detect(type);
    }
}

