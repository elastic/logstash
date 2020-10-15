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
import org.apache.commons.csv.CSVRecord;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.net.URL;
import java.util.Objects;
import java.util.Scanner;
import java.util.SortedSet;

class Dependency implements Comparable<Dependency> {

    String name;
    String version;
    String url;
    String spdxLicense;
    String sourceURL;
    String copyright;

    /**
     * Returns an object array representing this dependency as a CSV record according
     * to the format requested here: https://github.com/elastic/logstash/issues/8725
     */
    Object[] toCsvReportRecord() {
        return new String[] {name, version, "", url, spdxLicense, copyright, sourceURL};
    }

    /**
     * Reads dependencies from the specified stream using the Ruby dependency report format
     * and adds them to the supplied set.
     */
    static void addDependenciesFromRubyReport(InputStream stream, SortedSet<Dependency> dependencies)
            throws IOException {
        Reader in = new InputStreamReader(stream);
        for (CSVRecord record : CSVFormat.DEFAULT.withFirstRecordAsHeader().parse(in)) {
            dependencies.add(Dependency.fromRubyCsvRecord(record));
        }
    }

    /**
     * Reads dependencies from the specified stream using the Java dependency report format
     * and adds them to the supplied set.
     */
    static void addDependenciesFromJavaReport(InputStream stream, SortedSet<Dependency> dependencies)
            throws IOException {
        Reader in = new InputStreamReader(stream);
        for (CSVRecord record : CSVFormat.DEFAULT.withFirstRecordAsHeader().parse(in)) {
            dependencies.add(Dependency.fromJavaCsvRecord(record));
        }
    }

    private static Dependency fromRubyCsvRecord(CSVRecord record) {
        Dependency d = new Dependency();

        // name, version, url, license, copyright, sourceURL
        d.name = record.get(0);
        d.version = record.get(1);
        if (record.size() > 4) {
            d.copyright = record.get(4);
        }
        if (record.size() > 5) {
            d.sourceURL = record.get(5);
        }
        return d;
    }

    private static Dependency fromJavaCsvRecord(CSVRecord record) {
        Dependency d = new Dependency();

        // artifact,moduleUrl,moduleLicense,moduleLicenseUrl

        String nameAndVersion = record.get(0);
        int colonIndex = nameAndVersion.indexOf(':');
        if (colonIndex == -1) {
            String err = String.format("Could not parse java artifact name and version from '%s'",
                    nameAndVersion);
            throw new IllegalStateException(err);
        }
        colonIndex = nameAndVersion.indexOf(':', colonIndex + 1);
        String[] split = nameAndVersion.split(":");
        if (split.length != 3) {
            String err = String.format("Could not parse java artifact name and version from '%s', must be of the form group:name:version",
                    nameAndVersion);
            throw new IllegalStateException(err);
        }
        d.name = nameAndVersion.substring(0, colonIndex);
        d.version = nameAndVersion.substring(colonIndex + 1);

        // We DON'T read the license info out of this CSV because it is not reliable, we want humans
        // to use the overrides to ensure our license info is accurate

        return d;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        Dependency d = (Dependency) o;
        return Objects.equals(name, d.name);
    }

    @Override
    public int hashCode() {
        return Objects.hash(name);
    }

    @Override
    public int compareTo(Dependency o) {
        return (name).compareTo(o.name);
    }

    public String noticeSourcePath() {
        return "LS_HOME/tools/dependencies-report/src/main/resources/notices/" + noticeFilename();
    }

    /**
     * The name contains colons, which don't work on windows. The compatible name uses `!` which works on multiple platforms
     * @return
     */
    public String fsCompatibleName() {
        return name.replace(":", "!");
    }

    public String noticeFilename() {
        return String.format("%s-NOTICE.txt", fsCompatibleName());
    }

    public String resourceName() {
        return "/notices/" + noticeFilename();
    }

    public URL noticeURL() {
        return Dependency.class.getResource(resourceName());
    }

    public boolean noticeExists() {
        return noticeURL() != null;
    }

    public String notice() throws IOException {
       if (!noticeExists()) throw new IOException(String.format("No notice file found at '%s'", noticeFilename()));

       try (InputStream noticeStream = Dependency.class.getResourceAsStream(resourceName())) {
            return new Scanner(noticeStream, "UTF-8").useDelimiter("\\A").next();
       }
    }

    public String getName() {
        return name;
    }

    public String getVersion() {
        return version;
    }

    public String getSourceURL() {
        return sourceURL;
    }

    @Override
    public String toString() {
        return "<Dependency " + name + " v" + version + ">";
    }
}
