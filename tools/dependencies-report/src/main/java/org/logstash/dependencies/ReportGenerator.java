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

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVPrinter;
import org.apache.commons.csv.CSVRecord;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.SortedSet;
import java.util.TreeSet;

/**
 * Generates Java dependencies report for Logstash.
 *
 * See:
 * https://github.com/elastic/logstash/issues/8725
 * https://github.com/elastic/logstash/pull/8837
 * https://github.com/elastic/logstash/pull/9331
 */
public class ReportGenerator {

    final String UNKNOWN_LICENSE = "UNKNOWN";
    final Collection<Dependency> UNKNOWN_LICENSES = new ArrayList<>();
    final String[] CSV_HEADERS = {"name", "version", "revision", "url", "license", "copyright","sourceURL"};
    final Collection<Dependency> MISSING_NOTICE = new ArrayList<>();

    boolean generateReport(
            InputStream licenseMappingStream,
            InputStream acceptableLicensesStream,
            InputStream rubyDependenciesStream,
            InputStream[] javaDependenciesStreams,
            Writer licenseOutput,
            Writer noticeOutput,
            Writer unusedLicenseOutput) throws IOException {
        SortedSet<Dependency> dependencies = new TreeSet<>();

        Dependency.addDependenciesFromRubyReport(rubyDependenciesStream, dependencies);
        addJavaDependencies(javaDependenciesStreams, dependencies);

        Map<String, LicenseInfo> licenseMapping = new HashMap<>();
        checkDependencyLicenses(licenseMappingStream, acceptableLicensesStream, licenseMapping, dependencies);
        checkDependencyNotices(noticeOutput, dependencies);

        writeLicenseCSV(licenseOutput, dependencies);

        String msg = "Generated report with %d dependencies (%d unknown or unacceptable licenses, %d unknown or missing notices).";
        System.out.println(String.format(msg + "\n", dependencies.size(), UNKNOWN_LICENSES.size(), MISSING_NOTICE.size()));

        reportUnknownLicenses();
        reportMissingNotices();
        reportUnusedLicenseMappings(unusedLicenseOutput, licenseMapping);

        licenseOutput.close();
        noticeOutput.close();

        return UNKNOWN_LICENSES.isEmpty() && MISSING_NOTICE.isEmpty();
    }

    private void checkDependencyNotices(Writer noticeOutput, SortedSet<Dependency> dependencies) throws IOException {
        for (Dependency dependency : dependencies) {
            checkDependencyNotice(noticeOutput, dependency);
        }
    }

    private void checkDependencyLicenses(InputStream licenseMappingStream, InputStream acceptableLicensesStream,
                                         Map<String, LicenseInfo> licenseMapping, SortedSet<Dependency> dependencies) throws IOException {
        readLicenseMapping(licenseMappingStream, licenseMapping);
        List<String> acceptableLicenses = new ArrayList<>();
        readAcceptableLicenses(acceptableLicensesStream, acceptableLicenses);

        for (Dependency dependency : dependencies) {
            checkDependencyLicense(licenseMapping, acceptableLicenses, dependency);
        }
    }

    private void writeLicenseCSV(Writer output, SortedSet<Dependency> dependencies) throws IOException {
        try (CSVPrinter csvPrinter = new CSVPrinter(output,
                CSVFormat.DEFAULT.withHeader(CSV_HEADERS))) {
            for (Dependency dependency : dependencies) {
                csvPrinter.printRecord(dependency.toCsvReportRecord());
            }
            csvPrinter.flush();
        }
    }

    private void reportMissingNotices() {
        if (!MISSING_NOTICE.isEmpty()) {
            System.out.println("The following NOTICE.txt entries are missing, please add them:");
            for (Dependency dependency : MISSING_NOTICE) {
                System.out.println(dependency.noticeSourcePath());
            }
        }
    }

    private void reportUnknownLicenses() {
        if (!UNKNOWN_LICENSES.isEmpty()) {
            String errMsg =
                "Add complying licenses (using the SPDX license ID from https://spdx.org/licenses) " +
                "with URLs for the libraries listed below to tools/dependencies-report/src/main/resources/" +
                "licenseMapping.csv:";
            System.out.println(errMsg);
            for (Dependency dependency : UNKNOWN_LICENSES) {
                System.out.println(
                        String.format("\"%s:%s\"", dependency.name, dependency.version));
            }
        }
    }

    private void reportUnusedLicenseMappings(Writer unusedLicenseWriter, Map<String, LicenseInfo> licenseMapping) throws IOException {
        SortedSet<String> unusedDependencies = new TreeSet<>();

        for (Map.Entry<String, LicenseInfo> entry : licenseMapping.entrySet()) {
            if (entry.getValue().isUnused) {
                unusedDependencies.add(entry.getKey());
            }
        }

        if (unusedDependencies.size() > 0) {
            String msg = String.format("The following %d license mappings were specified but unused:", unusedDependencies.size());
            System.out.println(msg);
            unusedLicenseWriter.write(msg + System.lineSeparator());

            for (String dep : unusedDependencies) {
                System.out.println(dep);
                unusedLicenseWriter.write(dep + System.lineSeparator());
            }
        }
    }

    private void addJavaDependencies(InputStream[] javaDependenciesStreams, SortedSet<Dependency> dependencies) throws IOException {
        for (InputStream stream : javaDependenciesStreams) {
            Dependency.addDependenciesFromJavaReport(stream, dependencies);
        }
    }

    private void checkDependencyNotice(Writer noticeOutput, Dependency dependency) throws IOException {
        if (dependency.noticeExists()) {
            String notice = dependency.notice();

            boolean noticeIsBlank = notice.matches("\\A\\s*\\Z");
            if (!noticeIsBlank) {
                noticeOutput.write(String.format("\n==========\nNotice for: %s-%s\n----------\n\n", dependency.name, dependency.version));
                noticeOutput.write(notice);
            } else {
                MISSING_NOTICE.add(dependency);
            }
        } else {
            MISSING_NOTICE.add(dependency);
        }
    }

    private void checkDependencyLicense(Map<String, LicenseInfo> licenseMapping, List<String> acceptableLicenses, Dependency dependency) {
        if (licenseMapping.containsKey(dependency.name)) {
            LicenseInfo licenseInfo = licenseMapping.get(dependency.name);

            String[] dependencyLicenses = licenseInfo.license.split("\\|");
            boolean hasAcceptableLicense = false;
            if (licenseInfo.url != null && !licenseInfo.url.equals("")) {
                for (int k = 0; k < dependencyLicenses.length && !hasAcceptableLicense; k++) {
                    if (acceptableLicenses.stream().anyMatch(dependencyLicenses[k]::equalsIgnoreCase)) {
                        hasAcceptableLicense = true;
                    }
                }
            }

            if (hasAcceptableLicense) {
                dependency.spdxLicense = licenseInfo.license;
                dependency.url = licenseInfo.url;
                dependency.sourceURL = licenseInfo.sourceURL;
                dependency.copyright = licenseInfo.copyright;
                licenseInfo.isUnused = false;
            } else {
                // unacceptable license or missing URL
                UNKNOWN_LICENSES.add(dependency);
            }
        } else {
            dependency.spdxLicense = UNKNOWN_LICENSE;
            UNKNOWN_LICENSES.add(dependency);
        }
    }

    private void readAcceptableLicenses(InputStream stream, List<String> acceptableLicenses)
            throws IOException {
        Reader in = new InputStreamReader(stream);
        for (CSVRecord record : CSVFormat.DEFAULT.parse(in)) {
            String acceptableLicenseId = record.get(0);
            if (acceptableLicenseId != null && !acceptableLicenseId.equals("")) {
                acceptableLicenses.add(acceptableLicenseId);
            }
        }
    }

    private void readLicenseMapping(InputStream stream, Map<String, LicenseInfo> licenseMapping)
            throws IOException {
        Reader in = new InputStreamReader(stream);
        for (CSVRecord record : CSVFormat.DEFAULT.withFirstRecordAsHeader().parse(in)) {
            String dependencyNameAndVersion = record.get(0);
            if (dependencyNameAndVersion != null && !dependencyNameAndVersion.equals("")) {
                int lastIndex = dependencyNameAndVersion.lastIndexOf(':');
                String depName = lastIndex < 0
                        ? dependencyNameAndVersion
                        : dependencyNameAndVersion.substring(0,  lastIndex);

                validateAndAdd(licenseMapping, depName, LicenseInfo.fromCSVRecord(record));
            }
        }
    }

    private static void validateAndAdd(Map<String, LicenseInfo> licenses, String depName, LicenseInfo lup) {
        if (licenses.containsKey(depName)) {
            LicenseInfo existingLicense = licenses.get(depName);

            // Because dependency versions are not treated independently, if dependencies with different versions
            // have different licenses, we cannot distinguish between them
            if (!existingLicense.license.equals(lup.license)) {
                String err = String.format("License mapping contains duplicate dependencies '%s' with conflicting " +
                        "licenses '%s' and '%s'", depName, existingLicense.license, lup.license);
                throw new IllegalStateException(err);
            }
        } else {
            licenses.put(depName, lup);
        }
    }

}

class LicenseInfo {
    String license;
    String url;
    String sourceURL;
    String copyright;
    boolean isUnused = true;

    LicenseInfo(String license, String url) {
        this.license = license;
        this.url = url;
    }

    static LicenseInfo fromCSVRecord(CSVRecord record){
        LicenseInfo info = new LicenseInfo(record.get(2), record.get(1));
        if (record.size() > 3){
            info.copyright = record.get(3);
        }
        if (record.size() > 4){
            info.sourceURL = record.get(4);
        }
        return info;
    }
}
