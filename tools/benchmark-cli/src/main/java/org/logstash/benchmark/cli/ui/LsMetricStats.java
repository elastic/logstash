package org.logstash.benchmark.cli.ui;

/**
 * Groups of statistics this tool gathers.
 */
public enum LsMetricStats {
    /**
     * Statistics on the event throughput.
     */
    THROUGHPUT,
    /**
     * Statistics on the number of events processed overall.
     */
    COUNT,
    /**
     * Statistics on CPU usage.
     */
    CPU_USAGE
}
