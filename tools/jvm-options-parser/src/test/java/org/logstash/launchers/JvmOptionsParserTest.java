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
        assertTrue("Output MUST contains the options present in LS_JAVA_OPTS", output.contains("-Xblabla"));
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
        assertTrue("Contains regexp interruptible for Java 17",
                JvmOptionsParser.getMandatoryJvmOptions(17).contains("-Djruby.regexp.interruptible=true"));

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

    private void verifyOptions(String message, String expected, JvmOptionsParser.ParseResult res) {
        assertEquals(message, expected, String.join(System.lineSeparator(), res.getJvmOptions()));
    }

    private BufferedReader asReader(String s) {
        return new BufferedReader(new StringReader(s));
    }
}