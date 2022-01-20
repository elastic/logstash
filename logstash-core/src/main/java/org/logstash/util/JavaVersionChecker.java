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

package org.logstash.util;

import java.util.Arrays;
import java.util.Locale;

/**
 * Simple program that checks if the runtime Java version is at least 11.
 * Based on JavaVersionChecker from Elasticsearch
 */
public final class JavaVersionChecker {

    private JavaVersionChecker() {}

    public static void bailOnOldJava() {
        if (JavaVersion.CURRENT.compareTo(JavaVersion.JAVA_11) < 0) {
            final String message = String.format(
                    Locale.ROOT,
                    "The minimum required Java version is 11; your Java version from [%s] does not meet this requirement",
                    System.getProperty("java.home")
            );
            errPrintln(message);
            exit(1);
        }
    }

    /**
     * Prints a string and terminates the line on standard error.
     *
     * @param message the message to print
     */
    static void errPrintln(final String message) {
        System.err.println(message);
    }

    /**
     * Exit the VM with the specified status.
     *
     * @param status the status
     */
    static void exit(final int status) {
        System.exit(status);
    }

}