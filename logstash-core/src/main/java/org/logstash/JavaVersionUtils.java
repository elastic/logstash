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

package org.logstash;

/**
 * Helper Class for dealing with Java versions
 */
public final class JavaVersionUtils {

    /**
     * Identifies whether we are running on a version greater than or equal to the version parameter specified.
     * @param version The version to test against. This must be the Major version of Java
     * @return True if running on Java whose major version is greater than or equal to the
     *         specified version.
     */
    public static boolean isJavaAtLeast(int version) {
        final String value = System.getProperty("java.specification.version");
        final int actualVersion;
        // Java specification version prior to Java 9 were of the format `1.X`, and after the format `X`
        // See https://openjdk.java.net/jeps/223
        if (value.startsWith("1.")) {
            actualVersion = Integer.parseInt(value.split("\\.")[1]);
        } else {
            actualVersion = Integer.parseInt(value);
        }
        return actualVersion >= version;
    }
}