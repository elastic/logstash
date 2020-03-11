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


package org.logstash.secret.cli;

import java.util.Scanner;

/**
 * Abstraction over System.console to allow graceful fallback to System.out
 */
public class Terminal {

    private static final boolean useConsole = Boolean.valueOf(System.getProperty("cli.console", String.valueOf(System.console() != null)));
    private static final Scanner scanner = new Scanner(System.in);

    /**
     * Writes a single line to the output.
     *
     * @param line the line to write.
     */
    public void writeLine(String line) {
        if (useConsole) {
            System.console().writer().println(line);
            System.console().writer().flush();
        } else {
            System.out.println(line);
        }
    }

    /**
     * Writes text to the output, but does not include a new line.
     *
     * @param text the text to write.
     */
    public void write(String text) {
        if (useConsole) {
            System.console().writer().print(text);
            System.console().writer().flush();
        } else {
            System.out.print(text);
        }
    }

    /**
     * Reads a single line
     *
     * @return the line
     */
    public String readLine() {
        if (useConsole) {
            return System.console().readLine();
        } else {
            return scanner.next();
        }

    }

    /**
     * Reads a secret
     *
     * @return the char[] representation of the secret.
     */
    public char[] readSecret() {
        if (useConsole) {
            return System.console().readPassword();
        } else {
            return scanner.next().toCharArray();
        }
    }


}
