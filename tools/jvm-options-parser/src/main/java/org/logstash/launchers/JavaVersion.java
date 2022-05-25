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

package org.logstash.launchers;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

/**
 * Helper class to compare current version of JVM with a target version.
 * Based on JavaVersion class from elasticsearch java version checker tool
 */
public class JavaVersion implements Comparable<JavaVersion> {

    public static final JavaVersion CURRENT = parse(System.getProperty("java.specification.version"));
    public static final JavaVersion JAVA_11 = parse("11");
    private final List<Integer> version;

    private JavaVersion(List<Integer> version){
        this.version = version;
    }

    static JavaVersion parse(final String value) {
        if (value.matches("^0*[0-9]+(\\.[0-9]+)*$") == false) {
            throw new IllegalArgumentException(value);
        }

        final List<Integer> version = new ArrayList<Integer>();
        final String[] components = value.split("\\.");
        for (final String component : components) {
            version.add(Integer.valueOf(component));
        }
        return new JavaVersion(version);
    }

    public static int majorVersion(final JavaVersion javaVersion) {
        Objects.requireNonNull(javaVersion);
        if (javaVersion.version.get(0) > 1) {
            return javaVersion.version.get(0);
        } else {
            return javaVersion.version.get(1);
        }
    }

    private static int compare(final JavaVersion leftVersion, final JavaVersion rightVersion) {
        List<Integer> left = leftVersion.version;
        List<Integer> right = rightVersion.version;
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

    @Override
    public int compareTo(JavaVersion other) {
        return compare(this, other);
    }
}