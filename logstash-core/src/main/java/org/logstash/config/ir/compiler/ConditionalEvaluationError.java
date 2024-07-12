package org.logstash.config.ir.compiler;

import org.logstash.Event;

/**
 * Exception raised when an if-condition in a pipeline throws an error at runtime.
 * */
public class ConditionalEvaluationError extends RuntimeException {
    private static final long serialVersionUID = -8633589068902565868L;
    private final Event failedEvent;

    ConditionalEvaluationError(Throwable cause, Event failedEvent) {
        super(cause);
        this.failedEvent = failedEvent;
    }

    public Event failedEvent() {
        return failedEvent;
    }
}
