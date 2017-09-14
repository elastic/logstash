package org.logstash.ackedqueue;

public class QueueRuntimeException extends RuntimeException {

    public QueueRuntimeException(String message, Throwable cause) {
        super(message, cause);
    }

}
