package org.logstash.ackedqueue;

public class QueueRuntimeException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    public QueueRuntimeException(String message, Throwable cause) {
        super(message, cause);
    }

}
