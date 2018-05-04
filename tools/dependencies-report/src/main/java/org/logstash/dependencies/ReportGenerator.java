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
    final Collection<Dependency> UNKNOWN_LICENSES = new ArrayList<Dependency>();

    public boolean generateReport(
            InputStream licenseMappingStream,
            InputStream acceptableLicensesStream,
            InputStream rubyDependenciesStream,
            InputStream[] javaDependenciesStreams,
            Writer output) throws IOException {

        SortedSet<Dependency> dependencies = new TreeSet<>();
        readRubyDependenciesReport(rubyDependenciesStream, dependencies);

        for (InputStream stream : javaDependenciesStreams) {
            readJavaDependenciesReport(stream, dependencies);
        }

        Map<String, LicenseUrlPair> licenseMapping = new HashMap<>();
        readLicenseMapping(licenseMappingStream, licenseMapping);
        List<String> acceptableLicenses = new ArrayList<>();
        readAcceptableLicenses(acceptableLicensesStream, acceptableLicenses);
        for (Dependency dependency : dependencies) {
            String nameAndVersion = dependency.name + ":" + dependency.version;
            if (licenseMapping.containsKey(nameAndVersion)) {
                LicenseUrlPair pair = licenseMapping.get(nameAndVersion);

                if (pair.url != null && !pair.url.equals("") &&
                   (acceptableLicenses.stream().anyMatch(pair.license::equalsIgnoreCase))) {
                    dependency.spdxLicense = pair.license;
                    dependency.url = pair.url;
                } else {
                    // unacceptable license or missing URL
                    UNKNOWN_LICENSES.add(dependency);
                }
            } else {
                dependency.spdxLicense = UNKNOWN_LICENSE;
                UNKNOWN_LICENSES.add(dependency);
            }
        }

        try (CSVPrinter csvPrinter = new CSVPrinter(output,
                CSVFormat.DEFAULT.withHeader("dependencyName", "dependencyVersion", "url", "license"))) {
            for (Dependency dependency : dependencies) {
                csvPrinter.printRecord(dependency.name, dependency.version, dependency.url, dependency.spdxLicense);
            }
            csvPrinter.flush();
        }

        String msg = "Generated report with %d dependencies (%d unknown or unacceptable licenses).";
        System.out.println(String.format(msg + "\n", dependencies.size(), UNKNOWN_LICENSES.size()));

        if (UNKNOWN_LICENSES.size() > 0) {
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

        return UNKNOWN_LICENSES.size() == 0;
    }

    private void readRubyDependenciesReport(InputStream stream, SortedSet<Dependency> dependencies)
            throws IOException {
        Reader in = new InputStreamReader(stream);
        for (CSVRecord record : CSVFormat.DEFAULT.withFirstRecordAsHeader().parse(in)) {
            dependencies.add(Dependency.fromRubyCsvRecord(record));
        }
    }

    private void readJavaDependenciesReport(InputStream stream, SortedSet<Dependency> dependencies)
            throws IOException {
        Reader in = new InputStreamReader(stream);
        for (CSVRecord record : CSVFormat.DEFAULT.withFirstRecordAsHeader().parse(in)) {
            dependencies.add(Dependency.fromJavaCsvRecord(record));
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

    private void readLicenseMapping(InputStream stream, Map<String, LicenseUrlPair> licenseMapping)
            throws IOException {
        Reader in = new InputStreamReader(stream);
        for (CSVRecord record : CSVFormat.DEFAULT.withFirstRecordAsHeader().parse(in)) {
            String dependencyNameAndVersion = record.get(0);
            if (dependencyNameAndVersion != null && !dependencyNameAndVersion.equals("")) {
                licenseMapping.put(dependencyNameAndVersion, new LicenseUrlPair(record.get(2), record.get(1)));
            }
        }
    }

}

class LicenseUrlPair {
    String license;
    String url;

    LicenseUrlPair(String license, String url) {
        this.license = license;
        this.url = url;
    }
}
