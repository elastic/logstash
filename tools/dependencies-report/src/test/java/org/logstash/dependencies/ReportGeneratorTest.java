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


package org.logstash.dependencies;

import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import java.io.IOException;
import java.io.InputStream;
import java.io.StringWriter;
import java.util.Optional;
import java.util.Scanner;
import java.util.regex.Pattern;

import static org.hamcrest.CoreMatchers.containsString;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.not;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertThat;
import static org.junit.Assert.assertTrue;
import static org.logstash.dependencies.Main.ACCEPTABLE_LICENSES_PATH;

public class ReportGeneratorTest {
    private StringWriter csvOutput;
    private StringWriter noticeOutput;
    private StringWriter unusedLicenseWriter;
    private ReportGenerator rg;

    @Before
    public void setup() {
        csvOutput = new StringWriter();
        noticeOutput = new StringWriter();
        unusedLicenseWriter = new StringWriter();
    }

    @Test
    // Tests both licenses and notices
    public void testSuccessfulReport() throws IOException {
        String expectedOutput = getStringFromStream(
                Main.getResourceAsStream("/expectedOutput.txt"));
        String expectedNoticeOutput = getStringFromStream(
                Main.getResourceAsStream("/expectedNoticeOutput.txt"));
        boolean result = runReportGenerator("/licenseMapping-good.csv", csvOutput, noticeOutput, unusedLicenseWriter);

        assertTrue(result);
        assertEquals(normalizeEol(expectedOutput), normalizeEol(csvOutput.toString()));
        assertEquals(normalizeEol(expectedNoticeOutput), normalizeEol(noticeOutput.toString()));
        String unusedLicenses = unusedLicenseWriter.toString();
        assertThat(unusedLicenses, containsString("41 license mappings were specified but unused"));
    }

    @Test
    public void testReportWithMissingLicenses() throws IOException {
        boolean result = runReportGenerator("/licenseMapping-missing.csv", csvOutput, noticeOutput, unusedLicenseWriter);

        assertFalse(result);

        // verify that the two components in the test input with missing licenses are
        // listed in the output with no license, i.e., an empty license field followed by CR/LF
        assertTrue(csvOutput.toString().contains("commons-io:commons-io,2.5,,,,,\r\n"));
        assertTrue(csvOutput.toString().contains("filesize,0.0.4,,,,,\r\n"));
        String unusedLicenses = unusedLicenseWriter.toString();
        assertThat(unusedLicenses, containsString("43 license mappings were specified but unused"));
    }

    @Test
    public void testReportWithConflictingLicenses() throws IOException {
        try {
            boolean result = runReportGenerator("/licenseMapping-conflicting.csv", csvOutput, noticeOutput, unusedLicenseWriter);
            Assert.fail("Conflicting licenses should have been detected");
        } catch (IllegalStateException ex) {
            assertThat(ex.getMessage(),
                    containsString("License mapping contains duplicate dependencies 'bundler' with conflicting licenses 'LGPL-2.0-only' and 'MIT'"));
        }
    }

    @Test
    public void testReportWithUnacceptableLicenses() throws IOException {
        boolean result = runReportGenerator("/licenseMapping-unacceptable.csv", csvOutput, noticeOutput, unusedLicenseWriter);

        assertFalse(result);

        // verify that the two components in the test input with unacceptable licenses are
        // listed in the output with no license, i.e., an empty license field followed by CR/LF
        String csvString = csvOutput.toString();
        assertThat(csvString, containsString("com.fasterxml.jackson.core:jackson-core,2.7.3,,,,,\r\n"));

        Pattern bundlerPattern = Pattern.compile(".*bundler,1\\.16\\.[0-1],,,,.*");
        assertThat(bundlerPattern.matcher(csvString).find(), is(true));
        String unusedLicenses = unusedLicenseWriter.toString();
        assertThat(unusedLicenses, containsString("43 license mappings were specified but unused"));
    }

    @Test
    public void testReportWithMissingUrls() throws IOException {
        boolean result = runReportGenerator("/licenseMapping-missingUrls.csv", csvOutput, noticeOutput, unusedLicenseWriter);

        assertFalse(result);

        // verify that the two components in the test input with missing URLs are
        // listed in the output with no license, i.e., an empty license field followed by CR/LF
        assertTrue(csvOutput.toString().contains("org.codehaus.janino:commons-compiler,3.0.8,,,,,\r\n"));
        assertTrue(csvOutput.toString().contains("json-parser,,,,,,\r\n"));
        String unusedLicenses = unusedLicenseWriter.toString();
        assertThat(unusedLicenses, containsString("43 license mappings were specified but unused"));
    }

    @Test
    public void testReportWithMissingNotices() throws IOException {
        boolean result = runReportGenerator(
                "/licenseMapping-good.csv",
                new InputStream[] {Main.getResourceAsStream("/javaLicensesMissingNotice.csv")},
                csvOutput,
                noticeOutput,
                unusedLicenseWriter
        );

        assertFalse(result);

        assertThat(noticeOutput.toString(), not(containsString("noNoticeDep")));
        Optional<Dependency> found = rg.MISSING_NOTICE.stream().filter(d -> d.getName().equals("co.elastic:noNoticeDep") && d.getVersion().equals("0.0.1")).findFirst();
        assertTrue(found.isPresent());
        String unusedLicenses = unusedLicenseWriter.toString();
        assertThat(unusedLicenses, containsString("45 license mappings were specified but unused"));
    }

    @Test
    public void testReportWithUnusedLicenses() throws IOException {
        boolean result = runReportGenerator(
                "/licenseMapping-missingNotices.csv",
                csvOutput,
                noticeOutput,
                unusedLicenseWriter
        );

        assertTrue("Unused licenses should not fail the license checker", result);

        String unusedLicenses = unusedLicenseWriter.toString();
        assertThat(unusedLicenses, containsString("42 license mappings were specified but unused"));
        assertThat(unusedLicenses, containsString("org.eclipse.core:org.eclipse.core.commands"));
        assertThat(unusedLicenses, not(containsString("junit:junit")));
    }

    private boolean runReportGenerator(String licenseMappingPath, StringWriter csvOutput, StringWriter noticeOutput, StringWriter unusedLicenseWriter) throws IOException {
       return runReportGenerator(
               licenseMappingPath,
               new InputStream[]{
                        Main.getResourceAsStream("/javaLicenses1.csv"),
                        Main.getResourceAsStream("/javaLicenses2.csv"),
                },
               csvOutput,
               noticeOutput,
               unusedLicenseWriter
       ) ;
    }

    private boolean runReportGenerator(
            String licenseMappingPath, InputStream[] javaLicenses, StringWriter csvOutput,
            StringWriter noticeOutput, StringWriter unusedLicenseWriter) throws IOException {
        rg = new ReportGenerator();
        return rg.generateReport(
                Main.getResourceAsStream(licenseMappingPath),
                Main.getResourceAsStream(ACCEPTABLE_LICENSES_PATH),
                Main.getResourceAsStream("/rubyDependencies.csv"),
                javaLicenses,
                csvOutput,
                noticeOutput,
                unusedLicenseWriter
        );
    }

    private static String getStringFromStream(InputStream stream) {
        return new Scanner(stream, "UTF-8").useDelimiter("\\A").next();
    }

    private static String normalizeEol(String s) {
        return s.replaceAll("\\r\\n", "\n");
    }
}
