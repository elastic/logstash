package org.logstash.instrument.reports;

import org.logstash.instrument.monitors.ProcessMonitor;

import java.util.Map;

public class ProcessReport {
    private ProcessReport() { }

    /**
     * Build a report with current Process information
     * @return a Map with the current process report
     */
    public static Map<String, Object> generate() {
        return ProcessMonitor.detect().toMap();
    }
}
