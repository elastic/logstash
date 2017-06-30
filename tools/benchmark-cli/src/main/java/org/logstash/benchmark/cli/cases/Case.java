package org.logstash.benchmark.cli.cases;

import java.util.AbstractMap;
import org.logstash.benchmark.cli.ui.LsMetricStats;
import org.openjdk.jmh.util.ListStatistics;

/**
 * Definition of an executable test case.
 */
public interface Case {

    /**
     * Runs the Actual Test Case.
     * @return Map Containing Test Results
     */
    AbstractMap<LsMetricStats, ListStatistics> run();
}
