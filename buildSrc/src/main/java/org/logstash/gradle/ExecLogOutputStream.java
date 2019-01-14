package org.logstash.gradle;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;

/**
 * Stream that can be used to forward Gradle Exec task output to an arbitrary {@link PrintStream}.
 */
public final class ExecLogOutputStream extends ByteArrayOutputStream {

    /**
     * Underlying {@link PrintStream} to flush output to.
     */
    private final PrintStream stream;

    /**
     * Ctor.
     * @param stream PrintStream to flush to
     */
    public ExecLogOutputStream(final PrintStream stream) {
        this.stream = stream;
    }

    @Override
    public synchronized void flush() {
        stream.print(toString());
        reset();
    }
}
