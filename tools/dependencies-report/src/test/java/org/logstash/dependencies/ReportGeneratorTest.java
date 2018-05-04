package org.logstash.dependencies;

import org.junit.Test;

import java.io.IOException;
import java.io.InputStream;
import java.io.StringWriter;
import java.util.Scanner;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.logstash.dependencies.Main.ACCEPTABLE_LICENSES_PATH;

public class ReportGeneratorTest {

    @Test
    public void testSuccessfulReport() throws IOException {
        String expectedOutput = getStringFromStream(
                Main.getResourceAsStream("/expectedOutput.txt"));
        StringWriter output = new StringWriter();
        boolean result = runReportGenerator("/licenseMapping-good.csv", output);

        assertTrue(result);
        assertEquals(normalizeEol(expectedOutput), normalizeEol(output.toString()));
    }

    @Test
    public void testReportWithMissingLicenses() throws IOException {
        StringWriter output = new StringWriter();
        boolean result = runReportGenerator("/licenseMapping-missing.csv", output);

        assertFalse(result);

        // verify that the two components in the test input with missing licenses are
        // listed in the output with no license, i.e., an empty license field followed by CR/LF
        assertTrue(output.toString().contains("commons-io:commons-io,2.5,,\r\n"));
        assertTrue(output.toString().contains("filesize,0.0.4,,\r\n"));
    }

    @Test
    public void testReportWithUnacceptableLicenses() throws IOException {
        StringWriter output = new StringWriter();
        boolean result = runReportGenerator("/licenseMapping-unacceptable.csv", output);

        assertFalse(result);

        // verify that the two components in the test input with unacceptable licenses are
        // listed in the output with no license, i.e., an empty license field followed by CR/LF
        assertTrue(output.toString().contains("com.fasterxml.jackson.core:jackson-core,2.7.3,,\r\n"));
        assertTrue(output.toString().contains("bundler,1.16.0,,\r\n"));
    }

    @Test
    public void testReportWithMissingUrls() throws IOException {
        StringWriter output = new StringWriter();
        boolean result = runReportGenerator("/licenseMapping-missingUrls.csv", output);

        assertFalse(result);

        // verify that the two components in the test input with missing URLs are
        // listed in the output with no license, i.e., an empty license field followed by CR/LF
        assertTrue(output.toString().contains("org.codehaus.janino:commons-compiler,3.0.8,,\r\n"));
        assertTrue(output.toString().contains("json-parser,,,\r\n"));
    }

    private static boolean runReportGenerator(String licenseMappingPath, StringWriter output)
            throws IOException {
        ReportGenerator rg = new ReportGenerator();
        return rg.generateReport(
                Main.getResourceAsStream(licenseMappingPath),
                Main.getResourceAsStream(ACCEPTABLE_LICENSES_PATH),
                Main.getResourceAsStream("/rubyDependencies.csv"),
                new InputStream[]{
                        Main.getResourceAsStream("/javaLicenses1.csv"),
                        Main.getResourceAsStream("/javaLicenses2.csv"),
                },
                output
        );
    }

    private static String getStringFromStream(InputStream stream) {
        return new Scanner(stream, "UTF-8").useDelimiter("\\A").next();
    }

    private static String normalizeEol(String s) {
        return s.replaceAll("\\r\\n", "\n");
    }
}

