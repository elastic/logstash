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
