package org.logstash.dependencies;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVPrinter;
import org.apache.commons.csv.CSVRecord;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.io.Writer;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
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
    final String[] CSV_HEADERS = {"name", "version", "revision", "url", "license", "copyright"};
    public final Collection<Dependency> MISSING_NOTICE = new ArrayList<Dependency>();

    public boolean generateReport(
            InputStream licenseMappingStream,
            InputStream acceptableLicensesStream,
            InputStream rubyDependenciesStream,
            InputStream[] javaDependenciesStreams,
            Writer licenseOutput,
            Writer noticeOutput) throws IOException {
        SortedSet<Dependency> dependencies = new TreeSet<>();

        Dependency.addDependenciesFromRubyReport(rubyDependenciesStream, dependencies);
        addJavaDependencies(javaDependenciesStreams, dependencies);

        checkDependencyLicenses(licenseMappingStream, acceptableLicensesStream, dependencies);
        checkDependencyNotices(noticeOutput, dependencies);

        writeLicenseCSV(licenseOutput, dependencies);

        String msg = "Generated report with %d dependencies (%d unknown or unacceptable licenses, %d unknown or missing notices).";
        System.out.println(String.format(msg + "\n", dependencies.size(), UNKNOWN_LICENSES.size(), MISSING_NOTICE.size()));

        reportUnknownLicenses();
        reportMissingNotices();

        licenseOutput.close();
        noticeOutput.close();

        return UNKNOWN_LICENSES.isEmpty() && MISSING_NOTICE.isEmpty();
    }

    private void checkDependencyNotices(Writer noticeOutput, SortedSet<Dependency> dependencies) throws IOException {
        for (Dependency dependency : dependencies) {
            checkDependencyNotice(noticeOutput, dependency);
        }
    }

    private void checkDependencyLicenses(InputStream licenseMappingStream, InputStream acceptableLicensesStream, SortedSet<Dependency> dependencies) throws IOException {
        Map<String, LicenseUrlPair> licenseMapping = new HashMap<>();
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

    private void checkDependencyLicense(Map<String, LicenseUrlPair> licenseMapping, List<String> acceptableLicenses, Dependency dependency) {
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
