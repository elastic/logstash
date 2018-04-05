package org.logstash.dependencies;

import org.apache.commons.csv.CSVRecord;

import java.util.Objects;

class Dependency implements Comparable<Dependency> {
    public static final String RUBY_TYPE = "ruby";
    public static final String JAVA_TYPE = "java";

    String type;
    String name;
    String version;
    String license;
    String spdxLicense;

    // optional
    String licenseUrl;

    public static Dependency fromRubyCsvRecord(CSVRecord record) {
        Dependency d = new Dependency();

        // name, version, url, license
        d.type = RUBY_TYPE;
        d.name = record.get(0);
        d.version = record.get(1);
        d.license = record.get(3);

        return d;
    }

    public static Dependency fromJavaCsvRecord(CSVRecord record) {
        Dependency d = new Dependency();

        // artifact,moduleUrl,moduleLicense,moduleLicenseUrl
        d.type = JAVA_TYPE;

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
