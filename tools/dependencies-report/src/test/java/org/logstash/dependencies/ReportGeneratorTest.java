package org.logstash.dependencies;

import org.junit.Before;
import org.junit.Test;

import java.io.IOException;
import java.io.InputStream;
import java.io.StringWriter;
import java.util.Optional;
import java.util.Scanner;

import static org.hamcrest.CoreMatchers.containsString;
import static org.hamcrest.CoreMatchers.not;
import static org.junit.Assert.*;
import static org.logstash.dependencies.Main.ACCEPTABLE_LICENSES_PATH;

public class ReportGeneratorTest {
    StringWriter csvOutput;
    StringWriter noticeOutput;
    ReportGenerator rg;

    @Before
    public void setup() {
        csvOutput = new StringWriter();
        noticeOutput = new StringWriter();
    }

    @Test
    // Tests both licenses and notices
    public void testSuccessfulReport() throws IOException {
        String expectedOutput = getStringFromStream(
                Main.getResourceAsStream("/expectedOutput.txt"));
        String expectedNoticeOutput = getStringFromStream(
                Main.getResourceAsStream("/expectedNoticeOutput.txt"));
        boolean result = runReportGenerator("/licenseMapping-good.csv", csvOutput, noticeOutput);

        assertTrue(result);
        assertEquals(normalizeEol(expectedOutput), normalizeEol(csvOutput.toString()));
        assertEquals(normalizeEol(expectedNoticeOutput), normalizeEol(noticeOutput.toString()));
    }

    @Test
    public void testReportWithMissingLicenses() throws IOException {
        boolean result = runReportGenerator("/licenseMapping-missing.csv", csvOutput, noticeOutput);

        assertFalse(result);

        // verify that the two components in the test input with missing licenses are
        // listed in the output with no license, i.e., an empty license field followed by CR/LF
        assertTrue(csvOutput.toString().contains("commons-io:commons-io,2.5,,,,\r\n"));
        assertTrue(csvOutput.toString().contains("filesize,0.0.4,,,,\r\n"));
    }

    @Test
    public void testReportWithUnacceptableLicenses() throws IOException {
        boolean result = runReportGenerator("/licenseMapping-unacceptable.csv", csvOutput, noticeOutput);

        assertFalse(result);

        // verify that the two components in the test input with unacceptable licenses are
        // listed in the output with no license, i.e., an empty license field followed by CR/LF
        assertThat(csvOutput.toString(), containsString("com.fasterxml.jackson.core:jackson-core,2.7.3,,,,\r\n"));
        assertThat(csvOutput.toString(), containsString("bundler,1.16.0,,,,\r\n"));
    }

    @Test
    public void testReportWithMissingUrls() throws IOException {
        boolean result = runReportGenerator("/licenseMapping-missingUrls.csv", csvOutput, noticeOutput);

        assertFalse(result);

        // verify that the two components in the test input with missing URLs are
        // listed in the output with no license, i.e., an empty license field followed by CR/LF
        assertTrue(csvOutput.toString().contains("org.codehaus.janino:commons-compiler,3.0.8,,,,\r\n"));
        assertTrue(csvOutput.toString().contains("json-parser,,,,,\r\n"));
    }

    @Test
    public void testReportWithMissingNotices() throws IOException {
        boolean result = runReportGenerator(
                "/licenseMapping-missingNotices.csv",
                new InputStream[] {Main.getResourceAsStream("/javaLicensesMissingNotice.csv")},
                csvOutput,
                noticeOutput
        );

        assertFalse(result);

        assertThat(noticeOutput.toString(), not(containsString("noNoticeDep")));
        Optional<Dependency> found = rg.MISSING_NOTICE.stream().filter(d -> d.getName().equals("co.elastic:noNoticeDep") && d.getVersion().equals("0.0.1")).findFirst();
        assertTrue(found.isPresent());
    }

    private boolean runReportGenerator(String licenseMappingPath, StringWriter csvOutput, StringWriter noticeOutput) throws IOException {
       return runReportGenerator(
               licenseMappingPath,
               new InputStream[]{
                        Main.getResourceAsStream("/javaLicenses1.csv"),
                        Main.getResourceAsStream("/javaLicenses2.csv"),
                },
               csvOutput,
               noticeOutput
       ) ;
    }

    private boolean runReportGenerator(String licenseMappingPath, InputStream[] javaLicenses, StringWriter csvOutput, StringWriter noticeOutput)
            throws IOException {
        rg = new ReportGenerator();
        return rg.generateReport(
                Main.getResourceAsStream(licenseMappingPath),
                Main.getResourceAsStream(ACCEPTABLE_LICENSES_PATH),
                Main.getResourceAsStream("/rubyDependencies.csv"),
                javaLicenses,
                csvOutput,
                noticeOutput
        );
    }

    private static String getStringFromStream(InputStream stream) {
        return new Scanner(stream, "UTF-8").useDelimiter("\\A").next();
    }

    private static String normalizeEol(String s) {
        return s.replaceAll("\\r\\n", "\n");
    }
}

