package org.logstash.instrument.reports;

import org.logstash.instrument.monitors.HotThreadsMonitor;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * A ThreadsReport object used to hold the hot threads information
 * Created by purbon on 12/12/15.
 */
public class ThreadsReport {


    /**
     * Generate a report with current Thread information
     * @param options Map of options to narrow this method functionality:
     *                Keys: ordered_by - can be "cpu", "wait" or "block"
     *                      stacktrace_size - max depth of stack trace
     * @return A Map containing hot threads information
     */
    public static Map<String, Object> generate(Map<String, String> options) {
        HotThreadsMonitor reporter = new HotThreadsMonitor();
        List<HotThreadsMonitor.ThreadReport> reports = reporter.detect(options);
        return reports
                .stream()
                .collect(Collectors
                    .toMap(HotThreadsMonitor.ThreadReport::getThreadName,
                           HotThreadsMonitor.ThreadReport::toMap));
    }


    /**
     * Generate a report with current Thread information
     * @return A Map containing the hot threads information
     */
    public static Map<String, Object> generate() {
        Map<String, String> options = new HashMap<>();
        options.put("order_by", "cpu");
        return generate(options);
    }
}

