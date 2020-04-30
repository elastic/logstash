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

import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.StringWriter;
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
        StringWriter unusedLicenseWriter = new StringWriter();

        boolean reportResult = new ReportGenerator().generateReport(
                getResourceAsStream(LICENSE_MAPPING_PATH),
                getResourceAsStream(ACCEPTABLE_LICENSES_PATH),
                rubyDependenciesStream,
                javaDependenciesStreams,
                licenseCSVWriter,
                noticeWriter,
                unusedLicenseWriter
        );

        // If there were unknown results in the report, exit with a non-zero status
        System.exit(reportResult ? 0 : 1);
    }

    static InputStream getResourceAsStream(String resourcePath) {
        return ReportGenerator.class.getResourceAsStream(resourcePath);
    }
}
