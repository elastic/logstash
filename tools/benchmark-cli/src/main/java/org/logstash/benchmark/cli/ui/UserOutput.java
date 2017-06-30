package org.logstash.benchmark.cli.ui;

import java.io.PrintStream;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;

public final class UserOutput {

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
        green(
            "██╗      ██████╗  ██████╗ ███████╗████████╗ █████╗ ███████╗██╗  ██╗          \n" +
                "██║     ██╔═══██╗██╔════╝ ██╔════╝╚══██╔══╝██╔══██╗██╔════╝██║  ██║          \n" +
                "██║     ██║   ██║██║  ███╗███████╗   ██║   ███████║███████╗███████║          \n" +
                "██║     ██║   ██║██║   ██║╚════██║   ██║   ██╔══██║╚════██║██╔══██║          \n" +
                "███████╗╚██████╔╝╚██████╔╝███████║   ██║   ██║  ██║███████║██║  ██║          \n" +
                "╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝          \n" +
                "                                                                             \n" +
                "██████╗ ███████╗███╗   ██╗ ██████╗██╗  ██╗███╗   ███╗ █████╗ ██████╗ ██╗  ██╗\n" +
                "██╔══██╗██╔════╝████╗  ██║██╔════╝██║  ██║████╗ ████║██╔══██╗██╔══██╗██║ ██╔╝\n" +
                "██████╔╝█████╗  ██╔██╗ ██║██║     ███████║██╔████╔██║███████║██████╔╝█████╔╝ \n" +
                "██╔══██╗██╔══╝  ██║╚██╗██║██║     ██╔══██║██║╚██╔╝██║██╔══██║██╔══██╗██╔═██╗ \n" +
                "██████╔╝███████╗██║ ╚████║╚██████╗██║  ██║██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██╗\n" +
                "╚═════╝ ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝\n" +
                "                                                                             ");
    }

    public void green(final String line) {
        target.println(colorize(line, "\u001B[32m"));
    }

    private static String colorize(final String line, final String prefix) {
        final String reset = "\u001B[0m";
        return new StringBuilder(line.length() + 2 * reset.length())
            .append(prefix).append(line).append(reset).toString();
    }
}
