package org.logstash.execution;

public class PipelineException extends RuntimeException {
    private static final long serialVersionUID = 1L;

    public PipelineException(final String message){
        super(message);
    }
}
