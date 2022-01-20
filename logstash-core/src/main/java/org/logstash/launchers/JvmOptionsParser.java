package org.logstash.launchers;

import org.logstash.util.JavaVersionChecker;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.SortedMap;
import java.util.TreeMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;


/**
 * Parse jvm.options file applying version conditional logic. Heavily inspired by same functionality in Elasticsearch.
 * */
public class JvmOptionsParser {

    static class JvmOptionsFileParserException extends Exception {

        private static final long serialVersionUID = 2446165130736962758L;

        private final Path jvmOptionsFile;

        Path jvmOptionsFile() {
            return jvmOptionsFile;
        }

        private final SortedMap<Integer, String> invalidLines;

        SortedMap<Integer, String> invalidLines() {
            return invalidLines;
        }

        JvmOptionsFileParserException(final Path jvmOptionsFile, final SortedMap<Integer, String> invalidLines) {
            this.jvmOptionsFile = jvmOptionsFile;
            this.invalidLines = invalidLines;
        }

    }

    private final String logstashHome;

    JvmOptionsParser(String logstashHome) {
        this.logstashHome = logstashHome;
    }

    /**
     * The main entry point. The exit code is 0 if the JVM options were successfully parsed, otherwise the exit code is 1. If an improperly
     * formatted line is discovered, the line is output to standard error.
     *
     * @param args the args to the program which should consist of a single option, the path to LOGSTASH_HOME
     */
    public static void main(final String[] args) throws InterruptedException, IOException {
        if (args.length < 1 || args.length > 2) {
            throw new IllegalArgumentException(
                    "Expected two arguments specifying path to LOGSTASH_HOME and an optional LS_JVM_OPTS, but was " + Arrays.toString(args)
            );
        }
        JavaVersionChecker.bailOnOldJava();
        final String lsJavaOpts = System.getenv("LS_JAVA_OPTS");
        handleJvmOptions(args, lsJavaOpts);
    }

    static void handleJvmOptions(String[] args, String lsJavaOpts) {
        final JvmOptionsParser parser = new JvmOptionsParser(args[0]);
        final String jvmOpts = args.length == 2 ? args[1] : null;
        try {
            Optional<Path> jvmOptions = parser.lookupJvmOptionsFile(jvmOpts);
            parser.parseAndInjectEnvironment(jvmOptions, lsJavaOpts);
        } catch (JvmOptionsFileParserException pex) {
            System.err.printf(Locale.ROOT,
                    "encountered [%d] error%s parsing [%s]",
                    pex.invalidLines().size(),
                    pex.invalidLines().size() == 1 ? "" : "s",
                    pex.jvmOptionsFile());
            int errorCounter = 0;
            for (final Map.Entry<Integer, String> entry : pex.invalidLines().entrySet()) {
                errorCounter++;
                System.err.printf(Locale.ROOT,
                        "[%d]: encountered improperly formatted JVM option in [%s] on line number [%d]: [%s]",
                        errorCounter,
                        pex.jvmOptionsFile(),
                        entry.getKey(),
                        entry.getValue());
            }
        } catch (IOException ex) {
            System.err.println("Error accessing jvm.options file");
            System.exit(1);
        }
    }

    private Optional<Path> lookupJvmOptionsFile(String jvmOpts) {
        if (jvmOpts != null && !jvmOpts.isEmpty()) {
            return Optional.of(Paths.get(jvmOpts));
        }
        // Set the initial JVM options from the jvm.options file. Look in
        // /etc/logstash first, and break if that file is found readable there.
        return Arrays.stream(new Path[] { Paths.get("/etc/logstash/jvm.options"),
                                          Paths.get(logstashHome, "config/jvm.options") })
                .filter(p -> p.toFile().canRead())
                .findFirst();
    }

    private void parseAndInjectEnvironment(Optional<Path> jvmOptionsFile, String lsJavaOpts) throws IOException, JvmOptionsFileParserException {
        final List<String> jvmOptionsContent = new ArrayList<>(parseJvmOptions(jvmOptionsFile));

        if (lsJavaOpts != null && !lsJavaOpts.isEmpty()) {
            if (isDebugEnabled()) {
                System.err.println("Appending jvm options from environment LS_JAVA_OPTS");
            }
            jvmOptionsContent.add(lsJavaOpts);
        }

        System.out.println(String.join(" ", jvmOptionsContent));
    }

    private List<String> parseJvmOptions(Optional<Path> jvmOptionsFile) throws IOException, JvmOptionsFileParserException {
        if (!jvmOptionsFile.isPresent()) {
            System.err.println("Warning: no jvm.options file found.");
            return Collections.emptyList();
        }
        final Path optionsFilePath = jvmOptionsFile.get();
        if (!optionsFilePath.toFile().exists()) {
            System.err.format("Warning: jvm.options file does not exist or is not readable: `%s`\n", optionsFilePath);
            return Collections.emptyList();
        }

        if (isDebugEnabled()) {
            System.err.format("Processing jvm.options file at `%s`\n", optionsFilePath);
        }
        final int majorJavaVersion = javaMajorVersion();

        try (InputStream is = Files.newInputStream(optionsFilePath);
             Reader reader = new InputStreamReader(is, StandardCharsets.UTF_8);
             BufferedReader br = new BufferedReader(reader)
        ) {
            final ParseResult parseResults = parse(majorJavaVersion, br);
            if (parseResults.hasErrors()) {
                throw new JvmOptionsFileParserException(optionsFilePath, parseResults.getInvalidLines());
            }
            return parseResults.getJvmOptions();
        }
    }

    private boolean isDebugEnabled() {
        final String debug = System.getenv("DEBUG");
        if (debug == null) {
            return false;
        }

        return "1".equals(debug) || Boolean.parseBoolean(debug);
    }

    /**
     * Collector of parsed lines and errors.
     * */
    static final class ParseResult {
        private final List<String> jvmOptions = new ArrayList<>();
        private final SortedMap<Integer, String> invalidLines = new TreeMap<>();

        void appendOption(String option) {
            jvmOptions.add(option);
        }

        void appendError(int lineNumber, String malformedLine) {
            invalidLines.put(lineNumber, malformedLine);
        }

        public boolean hasErrors() {
            return !invalidLines.isEmpty();
        }

        public SortedMap<Integer, String> getInvalidLines() {
            return invalidLines;
        }

        public List<String> getJvmOptions() {
            return jvmOptions;
        }
    }

    private static final Pattern OPTION_DEFINITION = Pattern.compile("((?<start>\\d+)(?<range>-)?(?<end>\\d+)?:)?(?<option>-.*)$");

    /**
     * Parse the line-delimited JVM options from the specified buffered reader for the specified Java major version.
     * Valid JVM options are:
     * <ul>
     *     <li>
     *         a line starting with a dash is treated as a JVM option that applies to all versions
     *     </li>
     *     <li>
     *         a line starting with a number followed by a colon is treated as a JVM option that applies to the matching Java major version
     *         only
     *     </li>
     *     <li>
     *         a line starting with a number followed by a dash followed by a colon is treated as a JVM option that applies to the matching
     *         Java specified major version and all larger Java major versions
     *     </li>
     *     <li>
     *         a line starting with a number followed by a dash followed by a number followed by a colon is treated as a JVM option that
     *         applies to the specified range of matching Java major versions
     *     </li>
     * </ul>
     *
     * For example, if the specified Java major version is 8, the following JVM options will be accepted:
     * <ul>
     *     <li>
     *         {@code -XX:+PrintGCDateStamps}
     *     </li>
     *     <li>
     *         {@code 8:-XX:+PrintGCDateStamps}
     *     </li>
     *     <li>
     *         {@code 8-:-XX:+PrintGCDateStamps}
     *     </li>
     *     <li>
     *         {@code 7-8:-XX:+PrintGCDateStamps}
     *     </li>
     * </ul>
     * and the following JVM options will be skipped:
     * <ul>
     *     <li>
     *         {@code 9:-Xlog:age*=trace,gc*,safepoint:file=logs/gc.log:utctime,pid,tags:filecount=32,filesize=64m}
     *     </li>
     *     <li>
     *         {@code 9-:-Xlog:age*=trace,gc*,safepoint:file=logs/gc.log:utctime,pid,tags:filecount=32,filesize=64m}
     *     </li>
     *     <li>
     *         {@code 9-10:-Xlog:age*=trace,gc*,safepoint:file=logs/gc.log:utctime,pid,tags:filecount=32,filesize=64m}
     *     </li>
     * </ul>
     *
     * If the version syntax specified on a line matches the specified JVM options, the JVM option callback will be invoked with the JVM
     * option. If the line does not match the specified syntax for the JVM options, the invalid line callback will be invoked with the
     * contents of the entire line.
     *
     * @param javaMajorVersion the Java major version to match JVM options against
     * @param br the buffered reader to read line-delimited JVM options from
     * @return the admitted options lines respecting the javaMajorVersion and the error lines
     * @throws IOException if an I/O exception occurs reading from the buffered reader
     */
    static ParseResult parse(final int javaMajorVersion, final BufferedReader br) throws IOException {
        final ParseResult result = new ParseResult();
        int lineNumber = 0;
        while (true) {
            final String line = br.readLine();
            lineNumber++;
            if (line == null) {
                break;
            }
            if (line.startsWith("#")) {
                // lines beginning with "#" are treated as comments
                continue;
            }
            if (line.matches("\\s*")) {
                // skip blank lines
                continue;
            }
            final Matcher matcher = OPTION_DEFINITION.matcher(line);
            if (matcher.matches()) {
                final String start = matcher.group("start");
                final String end = matcher.group("end");
                if (start == null) {
                    // no range present, unconditionally apply the JVM option
                    result.appendOption(line);
                } else {
                    final int lower;
                    try {
                        lower = Integer.parseInt(start);
                    } catch (final NumberFormatException e) {
                        result.appendError(lineNumber, line);
                        continue;
                    }
                    final int upper;
                    if (matcher.group("range") == null) {
                        // no range is present, apply the JVM option to the specified major version only
                        upper = lower;
                    } else if (end == null) {
                        // a range of the form \\d+- is present, apply the JVM option to all major versions larger than the specified one
                        upper = Integer.MAX_VALUE;
                    } else {
                        // a range of the form \\d+-\\d+ is present, apply the JVM option to the specified range of major versions
                        try {
                            upper = Integer.parseInt(end);
                        } catch (final NumberFormatException e) {
                            result.appendError(lineNumber, line);
                            continue;
                        }
                        if (upper < lower) {
                            result.appendError(lineNumber, line);
                            continue;
                        }
                    }
                    if (lower <= javaMajorVersion && javaMajorVersion <= upper) {
                        result.appendOption(matcher.group("option"));
                    }
                }
            } else {
                result.appendError(lineNumber, line);
            }
        }
        return result;
    }

    private static final Pattern JAVA_VERSION = Pattern.compile("^(?:1\\.)?(?<javaMajorVersion>\\d+)(?:\\.\\d+)?$");

    private int javaMajorVersion() {
        final String specVersion = System.getProperty("java.specification.version");
        final Matcher specVersionMatcher = JAVA_VERSION.matcher(specVersion);
        if (!specVersionMatcher.matches()) {
            throw new IllegalStateException(String.format("Failed to extract Java major version from specification `%s`", specVersion));
        }
        return Integer.parseInt(specVersionMatcher.group("javaMajorVersion"));
    }
}
