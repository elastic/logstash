package org.logstash.common.failure;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.Event;

import java.util.Map;

public class DropFailureHandler implements FailureHandler {

    private static final Logger LOGGER = LogManager.getLogger(DropFailureHandler.class);

    @Override
    public void handle(Event event, Exception exception) {
        LOGGER.error("Dropping {} - {}", event.toMap(), exception);
        event.cancel();
    }

    @Override
    public void handle(Event event, Map<String, Object> failureMetadata, Exception exception) {
        LOGGER.error("Dropping {} - {}", event.toMap(), failureMetadata, exception);
        event.cancel();
    }

    @Override
    public void handle(Event event, Map<String, Object> failureMetadata) {
        LOGGER.error("Dropping {} - {}", event.toMap(), failureMetadata);
        event.cancel();
    }
}
