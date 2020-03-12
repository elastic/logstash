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


package org.logstash.benchmark.cli.ui;

import java.io.PrintStream;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.util.Map;
import org.apache.commons.lang3.SystemUtils;
import org.openjdk.jmh.util.ListStatistics;

public final class UserOutput {

    /**
     * ANSI colorized green section open sequence(On Unix platform only).
     */
    private static final String GREEN_ANSI_OPEN = SystemUtils.IS_OS_UNIX ? "\u001B[32m" : "";

    /**
     * ANSI colorized blue section open sequence(On Unix platform only).
     */
    private static final String BLUE_ANSI_OPEN = SystemUtils.IS_OS_UNIX ? "\u001B[34m" : "";

    /**
     * ANSI colorized section close sequence(On Unix platform only).
     */
    private static final String ANSI_CLOSE = SystemUtils.IS_OS_UNIX ? "\u001B[0m" : "";

    private static final String BANNER = "Logstash Benchmark";

    private static final DateTimeFormatter DATE_TIME_FORMATTER = new DateTimeFormatterBuilder()
        .append(DateTimeFormatter.ofPattern("E")).appendLiteral(' ')
        .append(DateTimeFormatter.ofPattern("L")).appendLiteral(' ')
        .append(DateTimeFormatter.ofPattern("d")).appendLiteral(' ')
        .append(DateTimeFormatter.ISO_LOCAL_TIME).appendLiteral(' ')
        .append(DateTimeFormatter.ofPattern("yyyy")).appendLiteral(' ')
        .append(DateTimeFormatter.ofPattern("z")).toFormatter();

    private final PrintStream target;

    public UserOutput(final PrintStream target) {
        this.target = target;
    }

    public void printStartTime() {
        green(
            String.format(
                "Start Time: %s", DATE_TIME_FORMATTER.format(ZonedDateTime.now().withNano(0))
            )
        );
    }

    public void printLine() {
        green("------------------------------------------");
    }

    public void printBanner() {
        green(BANNER);
    }

    public void green(final String line) {
        target.println(colorize(line, GREEN_ANSI_OPEN));
    }

    public void blue(final String line) {
        target.println(colorize(line, BLUE_ANSI_OPEN));
    }

    public void printStatistics(final Map<LsMetricStats, ListStatistics> stats) {
        green(
            String.format("Num Events: %d", (long) stats.get(LsMetricStats.COUNT).getMax())
        );
        final ListStatistics throughput = stats.get(LsMetricStats.THROUGHPUT);
        green(String.format("Throughput Min: %.2f", throughput.getMin()));
        green(String.format("Throughput Max: %.2f", throughput.getMax()));
        green(String.format("Throughput Mean: %.2f", throughput.getMean()));
        green(String.format("Throughput StdDev: %.2f", throughput.getStandardDeviation()));
        green(String.format("Throughput Variance: %.2f", throughput.getVariance()));
        green(
            String.format(
                "Mean CPU Usage: %.2f%%", stats.get(LsMetricStats.CPU_USAGE).getMean()
            )
        );
        green(
                String.format(
                        "Mean Heap Usage: %.2f%%", stats.get(LsMetricStats.HEAP_USAGE).getMean()
                )
        );
    }
    
    private static String colorize(final String line, final String prefix) {
        final String reset = ANSI_CLOSE;
        return new StringBuilder(line.length() + 2 * reset.length())
            .append(prefix).append(line).append(reset).toString();
    }
}
