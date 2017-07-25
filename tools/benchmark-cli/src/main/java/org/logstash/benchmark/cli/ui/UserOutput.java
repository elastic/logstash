package org.logstash.benchmark.cli.ui;

import java.io.PrintStream;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import org.apache.commons.lang3.SystemUtils;

public final class UserOutput {

    /**
     * ANSI colorized green section open sequence(On Unix platform only).
     */
    private static final String GREEN_ANSI_OPEN = SystemUtils.IS_OS_UNIX ? "\u001B[32m" : "";

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

    private static String colorize(final String line, final String prefix) {
        final String reset = ANSI_CLOSE;
        return new StringBuilder(line.length() + 2 * reset.length())
            .append(prefix).append(line).append(reset).toString();
    }
}
