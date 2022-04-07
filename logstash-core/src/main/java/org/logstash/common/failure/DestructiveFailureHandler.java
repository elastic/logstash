package org.logstash.common.failure;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.Event;

import java.util.Map;

public class DestructiveFailureHandler implements FailureHandler {

    private static final Logger LOGGER = LogManager.getLogger(DestructiveFailureHandler.class);

    @Override
    public void handle(Event event, Exception exception){
        LOGGER.error("Failure, blowing up the pipeline {}", event.toMap(), exception);
        throw new RuntimeException(exception);
    }

    @Override
    public void handle(Event event, Map<String, Object> failureMetadata, Exception exception){
        LOGGER.error("Failure, blowing up the pipeline {} - {}", event.toMap(), failureMetadata, exception);
        throw new RuntimeException(exception);
    }

    @Override
    public void handle(Event event, Map<String, Object> failureMetadata) {
        LOGGER.error("Failure, blowing up the pipeline {} - {}", event.toMap(), failureMetadata);
        throw new RuntimeException(failureMetadata.toString());
    }
}
