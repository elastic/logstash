package org.logstash;

import java.io.IOException;

public class LockException extends IOException {
    private static final long serialVersionUID = 4924559998318165488L;

    public LockException(String message) {
        super(message);
    }

    public LockException(String message, Throwable cause) {
        super(message, cause);
    }
}
