package org.logstash.dependencies;

import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

/**
 * Entry point for {@link ReportGenerator}.
 */
public class Main {

    static final String LICENSE_MAPPING_PATH = "/licenseMapping.csv";
    static final String ACCEPTABLE_LICENSES_PATH = "/acceptableLicenses.csv";

    public static void main(String[] args) throws IOException {
        if (args.length < 4) {
            System.out.println("Usage: org.logstash.dependencies.Main <pathToRubyDependencies.csv> <pathToJavaLicenseReportFolders.txt> <output.csv> <NOTICE.txt>");
            System.exit(1);
        }


        InputStream rubyDependenciesStream = new FileInputStream(args[0]);
        List<String> javaDependencyReports = Files.readAllLines(Paths.get(args[1]));
        InputStream[] javaDependenciesStreams = new InputStream[javaDependencyReports.size()];
        for (int k = 0; k < javaDependencyReports.size(); k++) {
            javaDependenciesStreams[k] = new FileInputStream(javaDependencyReports.get(k) + "/licenses.csv");
        }
        FileWriter licenseCSVWriter = new FileWriter(args[2]);
        FileWriter noticeWriter = new FileWriter(args[3]);

        boolean reportResult = new ReportGenerator().generateReport(
                getResourceAsStream(LICENSE_MAPPING_PATH),
                getResourceAsStream(ACCEPTABLE_LICENSES_PATH),
                rubyDependenciesStream,
                javaDependenciesStreams,
                licenseCSVWriter,
                noticeWriter
        );

        // If there were unknown results in the report, exit with a non-zero status
        //System.exit(reportResult ? 0 : 1);

    }

    static InputStream getResourceAsStream(String resourcePath) {
        return ReportGenerator.class.getResourceAsStream(resourcePath);
    }
}
