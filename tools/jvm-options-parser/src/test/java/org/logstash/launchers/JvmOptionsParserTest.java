package org.logstash.launchers;

import org.junit.After;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintStream;
import java.io.PrintWriter;
import java.io.StringReader;
import java.lang.reflect.Field;
import java.util.Map;
import java.util.function.Consumer;

import static org.junit.Assert.*;

public class JvmOptionsParserTest {

    @Rule
    public TemporaryFolder temp = new TemporaryFolder();

    private final PrintStream standardOut = System.out;
    private final ByteArrayOutputStream outputStreamCaptor = new ByteArrayOutputStream();

    @Before
    public void setUp() {
        System.setOut(new PrintStream(outputStreamCaptor));
    }

    @After
    public void tearDown() {
        System.setOut(standardOut);
    }

    @Test
    public void test_LS_JAVA_OPTS_isUsedWhenNoJvmOptionsIsAvailable() {
        JvmOptionsParser.handleJvmOptions(new String[] {temp.toString()}, "-Xblabla");

        // Verify
        final String output = outputStreamCaptor.toString();
        assertTrue("Output MUST contains the options present in LS_JAVA_OPTS", output.contains("-Xblabla"));
    }

    @Test
    public void givenLS_JAVA_OPTS_containingMultipleDefinitionsWithAlsoMaxOrderThenNoDuplicationOfMaxOrderOptionShouldHappen() throws IOException {
        JvmOptionsParser.handleJvmOptions(new String[] {temp.toString()}, "-Xblabla -Dio.netty.allocator.maxOrder=13");

        // Verify
        final String output = outputStreamCaptor.toString();
        int firstMatch = output.indexOf("-Dio.netty.allocator.maxOrder");
        int lastMatch = output.lastIndexOf("-Dio.netty.allocator.maxOrder");
        assertEquals("No duplication of options (io.netty.allocator.maxOrder) are admitted \n raw data[" + output + "]", firstMatch, lastMatch);
    }

    @SuppressWarnings({ "unchecked" })
    public static void updateEnv(String name, String val) throws ReflectiveOperationException {
        Map<String, String> env = System.getenv();
        Field field = env.getClass().getDeclaredField("m");
        field.setAccessible(true);
        ((Map<String, String>) field.get(env)).put(name, val);
    }


    @Test
    public void testParseCommentLine() throws IOException {
        final BufferedReader options = asReader("# this is a comment" + System.lineSeparator() + "-XX:+UseConcMarkSweepGC");
        final JvmOptionsParser.ParseResult res = JvmOptionsParser.parse(11, options);

        assertTrue("no invalid lines can be present", res.getInvalidLines().isEmpty());
        verifyOptions("Uncommented lines must be present", "-XX:+UseConcMarkSweepGC", res);
    }

    @Test
    public void testParseOptionWithFixedVersion() throws IOException {
        JvmOptionsParser.ParseResult res = JvmOptionsParser.parse(11, asReader("8:-XX:+UseConcMarkSweepGC"));

        assertTrue("No option match for Java 11", res.getJvmOptions().isEmpty());

        res = JvmOptionsParser.parse(8, asReader("8:-XX:+UseConcMarkSweepGC"));
        verifyOptions("Option must be present for Java 8", "-XX:+UseConcMarkSweepGC", res);
    }

    @Test
    public void testParseOptionGreaterThanVersion() throws IOException {
        JvmOptionsParser.ParseResult res = JvmOptionsParser.parse(11, asReader("8-:-XX:+UseConcMarkSweepGC"));
        verifyOptions("Option must be present for Java 11", "-XX:+UseConcMarkSweepGC", res);

        res = JvmOptionsParser.parse(8, asReader("8-:-XX:+UseConcMarkSweepGC"));
        verifyOptions("Option must be present also for Java 8", "-XX:+UseConcMarkSweepGC", res);
    }

    @Test
    public void testParseOptionVersionRange() throws IOException {
        JvmOptionsParser.ParseResult res = JvmOptionsParser.parse(11, asReader("10-11:-XX:+UseConcMarkSweepGC"));
        verifyOptions("Option must be present for Java 11", "-XX:+UseConcMarkSweepGC", res);

        res = JvmOptionsParser.parse(14, asReader("10-11:-XX:+UseConcMarkSweepGC"));
        assertTrue("No option match outside the range [10-11]", res.getJvmOptions().isEmpty());
    }

    @Test
    public void testMandatoryJvmOptionApplicableJvmPresent() throws IOException{
        assertTrue("Contains add-exports value for Java 17",
                JvmOptionsParser.getMandatoryJvmOptions(17).contains("--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED"));
    }

    @Test
    public void testMandatoryJvmOptionNonApplicableJvmNotPresent() throws IOException{
        assertFalse("Does not contains add-exports value for Java 11",
                JvmOptionsParser.getMandatoryJvmOptions(11).contains("--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED"));
    }

    @Test
    public void testAlwaysMandatoryJvmPresent() {
        assertTrue("Contains regexp interruptible for Java 11",
                JvmOptionsParser.getMandatoryJvmOptions(11).contains("-Djruby.regexp.interruptible=true"));
        assertTrue("Contains compile invokedynamic for Java 11",
                JvmOptionsParser.getMandatoryJvmOptions(11).contains("-Djruby.compile.invokedynamic=true"));
        assertTrue("Contains log4j2 isThreadContextMapInheritable for Java 11",
                JvmOptionsParser.getMandatoryJvmOptions(11).contains("-Dlog4j2.isThreadContextMapInheritable=true"));
        assertTrue("Contains regexp interruptible for Java 17",
                JvmOptionsParser.getMandatoryJvmOptions(17).contains("-Djruby.regexp.interruptible=true"));
        assertTrue("Contains compile invokedynamic for Java 17",
                JvmOptionsParser.getMandatoryJvmOptions(17).contains("-Djruby.compile.invokedynamic=true"));
        assertTrue("Contains log4j2 isThreadContextMapInheritable for Java 17",
                JvmOptionsParser.getMandatoryJvmOptions(17).contains("-Dlog4j2.isThreadContextMapInheritable=true"));

    }

    @Test
    public void testErrorLinesAreReportedCorrectly() throws IOException {
        final String jvmOptionsContent = "10-11:-XX:+UseConcMarkSweepGC" + System.lineSeparator() +
                "invalidOption" + System.lineSeparator() +
                "-Duser.country=US" + System.lineSeparator() +
                "anotherInvalidOption";
        JvmOptionsParser.ParseResult res = JvmOptionsParser.parse(11, asReader(jvmOptionsContent));
        verifyOptions("Option must be present for Java 11", "-XX:+UseConcMarkSweepGC" + System.lineSeparator() + "-Duser.country=US", res);

        assertEquals("invalidOption", res.getInvalidLines().get(2));
        assertEquals("anotherInvalidOption", res.getInvalidLines().get(4));
    }

    @Test
    public void testNettyMaxOrderRuleAppliesIfNotAlreadyDefinedExplicitlyByUser() throws IOException {
        File optionsFile = writeIntoTempOptionsFile(writer -> writer.println("-Dsome.other.netty.property=123"));

        JvmOptionsParser.handleJvmOptions(new String[] {"/path/to/ls_home", optionsFile.toString()}, "-Dcli.opts=something");

        // Verify
        final String output = outputStreamCaptor.toString();
        assertTrue("Existing properties other than Netty's maxOrder ar preserved", output.contains("-Dsome.other.netty.property=123"));
        assertTrue("Netty's maxOrder MUST be forcibly defined to the expected default", output.contains("-Dio.netty.allocator.maxOrder=11"));
    }

    @Test
    public void testNettyMaxOrderRuleDoNotAppliesIfAlreadyDefinedExplicitlyByUser() throws IOException {
        File optionsFile = writeIntoTempOptionsFile(writer -> writer.println("-Dio.netty.allocator.maxOrder=10"));

        JvmOptionsParser.handleJvmOptions(new String[] {"/path/to/ls_home", optionsFile.toString()}, "-Dcli.opts=something");

        // Verify
        final String output = outputStreamCaptor.toString();
        assertTrue("Netty's maxOrder MUST be forcibly defined to the expected default", output.contains("-Dio.netty.allocator.maxOrder=10"));

    }

    @Test
    public void testEnvironmentOPTSVariableTakesPrecedenceOverOptionsFile() throws IOException {
        String regex = "Xmx[^ ]+";
        String expected = "Xmx25g";
        File optionsFile = writeIntoTempOptionsFile(writer -> writer.println("-Xmx1g"));

        JvmOptionsParser.handleJvmOptions(new String[] {"/path/to/ls_home", optionsFile.toString()}, expected);

        final String output = outputStreamCaptor.toString();

        java.util.regex.Pattern pattern = java.util.regex.Pattern.compile(regex);
        String lastMatch = pattern.matcher(output)
                .results()
                .map(java.util.regex.MatchResult::group)
                .reduce((first, second) -> second)
                .orElse(null);

        assertEquals("LS_JAVA_OPTS env must take precedence over jvm.options file", expected, lastMatch);
    }

    private File writeIntoTempOptionsFile(Consumer<PrintWriter> writer) throws IOException {
        File optionsFile = temp.newFile("jvm.options");
        PrintWriter optionsWriter = new PrintWriter(new FileWriter(optionsFile));
        writer.accept(optionsWriter);
        optionsWriter.close();
        return optionsFile;
    }

    private void verifyOptions(String message, String expected, JvmOptionsParser.ParseResult res) {
        assertEquals(message, expected, String.join(System.lineSeparator(), res.getJvmOptions()));
    }

    private BufferedReader asReader(String s) {
        return new BufferedReader(new StringReader(s));
    }


    @Test
    public void testSingleEnvSub() throws IOException {
        String result = JvmOptionsParser.resolveEnvVar("-XX:HeapDumpPath=${LOGSTASH_HOME}/heapdump.hprof",
                Map.of("LOGSTASH_HOME", "/path/to/ls_home"));
        assertEquals("-XX:HeapDumpPath=/path/to/ls_home/heapdump.hprof", result);
    }

    @Test
    public void testMultipleEnvSub() throws IOException {
        String result = JvmOptionsParser.resolveEnvVar("-XX:HeapDumpPath=${LOGSTASH_HOME}/${DATA}/heapdump.hprof",
                Map.of("LOGSTASH_HOME", "/path/to/ls_home", "DATA", "data"));
        assertEquals("-XX:HeapDumpPath=/path/to/ls_home/data/heapdump.hprof", result);
    }

    @Test
    public void testPeriodEnvSub() throws IOException {
        String result = JvmOptionsParser.resolveEnvVar("-XX:HeapDumpPath=${.HOME}/heapdump.hprof",
                Map.of(".HOME", "/path/to/.home"));
        assertEquals("-XX:HeapDumpPath=/path/to/.home/heapdump.hprof", result);
    }

    @Test
    public void testEmptyEnvSub() throws IOException {
        String result = JvmOptionsParser.resolveEnvVar("-XX:HeapDumpPath=${NOT_VALID}/heapdump.hprof", Map.of());
        assertEquals("-XX:HeapDumpPath=/heapdump.hprof", result);
    }

    @Test
    public void testNoSub() throws IOException {
        String result = JvmOptionsParser.resolveEnvVar("   ", Map.of());
        assertEquals("   ", result);
    }

    @Test
    public void testEnvSubWithDefault() throws IOException {
        String result = JvmOptionsParser.resolveEnvVar("-XX:HeapDumpPath=${LOGSTASH_HOME:/usr/share/logstash}/${DATA:data}/heapdump.hprof",
                Map.of());
        assertEquals("-XX:HeapDumpPath=/usr/share/logstash/data/heapdump.hprof", result);
    }

    @Test
    public void testEnvSubWithDefaultSpecialChar() throws IOException {
        String result = JvmOptionsParser.resolveEnvVar("-XX:HeapDumpPath=${LOGSTASH_HOME:/usr/share/logstash}/${DATA:{$crazy!enough?'bless'@[you]}/heapdump.hprof",
                Map.of());
        assertEquals("-XX:HeapDumpPath=/usr/share/logstash/{$crazy!enough?'bless'@[you]/heapdump.hprof", result);
    }

    @Test
    public void testEnvSubWithDefaultOverwritten() throws IOException {
        String result = JvmOptionsParser.resolveEnvVar("-XX:HeapDumpPath=${LOGSTASH_HOME:/usr/share/logstash}/${DATA:data}/heapdump.hprof",
                Map.of("DATA", "data2"));
        assertEquals("-XX:HeapDumpPath=/usr/share/logstash/data2/heapdump.hprof", result);
    }

    @Test
    public void testEnvSubInFile() throws IOException {
        File optionsFile = writeIntoTempOptionsFile(
                writer -> writer.println("-Xlog:gc*,gc+age=trace,safepoint:file=${UNKNOWN}:"));

        JvmOptionsParser.handleJvmOptions(new String[] {"/path/to/ls_home", optionsFile.toString()}, "-Dcli.opts=something");

        final String output = outputStreamCaptor.toString();
        assertTrue("env variable should be substituted ", output.contains("-Xlog:gc*,gc+age=trace,safepoint:file=:"));
    }

    @Test
    public void testCommentedEnvSub() throws IOException {
        final BufferedReader options = asReader("# -Xlog:gc*,gc+age=trace,safepoint:file=${UNKNOWN}:");
        final JvmOptionsParser.ParseResult res = JvmOptionsParser.parse(11, options);

        assertTrue("no invalid lines can be present", res.getInvalidLines().isEmpty());
        assertFalse(String.join(System.lineSeparator(), res.getJvmOptions()).contains("-Xlog:gc*,gc+age=trace,safepoint"));
    }
}