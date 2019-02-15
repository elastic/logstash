package org.logstash.instrument.reports;

import org.logstash.instrument.monitors.SystemMonitor;

import java.util.Map;

public class SystemReport {
    private SystemReport() { }

    /**
     * Build a report with current System information
     * @return a Map with the current system report
     */
    public static Map<String, Object> generate() {
        return SystemMonitor.detect().toMap();
    }
}
