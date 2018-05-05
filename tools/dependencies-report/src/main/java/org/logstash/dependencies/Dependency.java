package org.logstash.dependencies;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVRecord;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.util.Objects;
import java.util.SortedSet;

class Dependency implements Comparable<Dependency> {

    String name;
    String version;
    String url;
    String spdxLicense;

    /**
     * Returns an object array representing this dependency as a CSV record according
     * to the format requested here: https://github.com/elastic/logstash/issues/8725
     */
    Object[] toCsvReportRecord() {
        return new String[] {name, version, "", url, spdxLicense, ""};
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

        // name, version, url, license
        d.name = record.get(0);
        d.version = record.get(1);

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
        if (colonIndex == -1) {
            String err = String.format("Could not parse java artifact name and version from '%s'",
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
        return Objects.equals(name, d.name) && Objects.equals(version, d.version);
    }

    @Override
    public int hashCode() {
        return Objects.hash(name, version);
    }

    @Override
    public int compareTo(Dependency o) {
        return (name + version).compareTo(o.name + o.version);
    }
}
