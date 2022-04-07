package org.logstash.common.failure;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.Event;
import org.logstash.common.dlq.IDeadLetterQueueWriter;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class DLQFailureHandler implements FailureHandler{

    private static final Logger LOGGER = LogManager.getLogger(DLQFailureHandler.class);
    private final IDeadLetterQueueWriter writer;

    public DLQFailureHandler(IDeadLetterQueueWriter writer){
        this.writer = writer;
    }

    public void handle(final Event event, final Exception exception) {
        Map<String, Object> failureMetadata = new HashMap<>();
        fillFailureMetadata(failureMetadata, exception);
        handle(event, failureMetadata);
    }

    @Override
    public void handle(final Event event, final Map<String, Object> failureMetadata, final Exception exception) {
        fillFailureMetadata(failureMetadata, exception);
        handle(event, failureMetadata);
    }

    @Override
    public void handle(final Event event, final Map<String, Object> failureMetadata) {
        try{
            LOGGER.warn("Writing {} to DLQ -> {}", event.toMap(), failureMetadata);
            writer.writeEntry(event, failureMetadata);
        } catch (IOException e){
            LOGGER.error("Unable to write to DLQ", e);
        }
    }
}
