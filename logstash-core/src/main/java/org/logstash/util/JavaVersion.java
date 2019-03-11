package org.logstash.util;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class JavaVersion {

    public static final List<Integer> CURRENT = parse(System.getProperty("java.specification.version"));
    public static final List<Integer> JAVA_8 = parse("1.8");

    static List<Integer> parse(final String value) {
        if (!value.matches("^0*[0-9]+(\\.[0-9]+)*$")) {
            throw new IllegalArgumentException(value);
        }

        final List<Integer> version = new ArrayList<Integer>();
        final String[] components = value.split("\\.");
        for (final String component : components) {
            version.add(Integer.valueOf(component));
        }
        return version;
    }

    public static int majorVersion(final List<Integer> javaVersion) {
        Objects.requireNonNull(javaVersion);
        if (javaVersion.get(0) > 1) {
            return javaVersion.get(0);
        } else {
            return javaVersion.get(1);
        }
    }

    static int compare(final List<Integer> left, final List<Integer> right) {
        // lexicographically compare two lists, treating missing entries as zeros
        final int len = Math.max(left.size(), right.size());
        for (int i = 0; i < len; i++) {
            final int l = (i < left.size()) ? left.get(i) : 0;
            final int r = (i < right.size()) ? right.get(i) : 0;
            if (l < r) {
                return -1;
            }
            if (r < l) {
                return 1;
            }
        }
        return 0;
    }


}
