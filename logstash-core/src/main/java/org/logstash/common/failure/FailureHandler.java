package org.logstash.common.failure;

import org.logstash.Event;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

// General Interface to handle failures. *Extremely* rough WIP
// Rubify to add to ExecutionContext

public interface FailureHandler {
    void handle(Event event, Exception exception);
    void handle(Event event, Map<String, Object> failureMetadata, Exception exception);
    void handle(Event event, Map<String, Object> failureMetadata);

    default void fillFailureMetadata(Map<String, Object> failureMetadata, Exception exception){
        failureMetadata.put("message", exception.getMessage());
        failureMetadata.put("type", exception.getClass().toString());
        failureMetadata.put("stack_trace", Arrays.toString(exception.getStackTrace()));
        Map<String, String> source = new HashMap<>();
        failureMetadata.put("source", source);
    }
}
