package org.logstash.launchers;

import org.junit.After;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.io.StringReader;
import java.lang.reflect.Field;
import java.util.Map;

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
    public void test_LS_JAVA_OPTS_isUsedWhenNoJvmOptionsIsAvailable() throws IOException, InterruptedException, ReflectiveOperationException {
        JvmOptionsParser.handleJvmOptions(new String[] {temp.toString()}, "-Xblabla");

        // Verify
        final String output = outputStreamCaptor.toString();
        assertEquals("Output MUST contains the options present in LS_JAVA_OPTS", "-Xblabla\n", output);
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
        final BufferedReader options = asReader("# this is a comment\n-XX:+UseConcMarkSweepGC");
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
    public void testErrorLinesAreReportedCorrectly() throws IOException {
        final String jvmOptionsContent = "10-11:-XX:+UseConcMarkSweepGC\n" +
                "invalidOption\n" +
                "-Duser.country=US\n" +
                "anotherInvalidOption";
        JvmOptionsParser.ParseResult res = JvmOptionsParser.parse(11, asReader(jvmOptionsContent));
        verifyOptions("Option must be present for Java 11", "-XX:+UseConcMarkSweepGC\n-Duser.country=US", res);

        assertEquals("invalidOption", res.getInvalidLines().get(2));
        assertEquals("anotherInvalidOption", res.getInvalidLines().get(4));
    }

    private void verifyOptions(String message, String expected, JvmOptionsParser.ParseResult res) {
        assertEquals(message, expected, String.join("\n", res.getJvmOptions()));
    }

    private BufferedReader asReader(String s) {
        return new BufferedReader(new StringReader(s));
    }
}