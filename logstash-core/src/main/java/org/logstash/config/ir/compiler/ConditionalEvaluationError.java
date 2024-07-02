package org.logstash.config.ir.compiler;

/**
 * Exception raised when an if-condition in a pipeline throws an error at runtime.
 * */
public class ConditionalEvaluationError extends RuntimeException {
    private static final long serialVersionUID = -8633589068902565868L;

    ConditionalEvaluationError(Throwable cause) {
        super(cause);
    }
}
