package org.logstash.plugins.pipeline;

import org.logstash.ext.JrubyEventExtLibrary;

import java.util.stream.Stream;

public interface PipelineInput {
    /**
     * Accepts an event
     * It might be rejected if the input is stopping
     * @param events a collection of events
     * @return true if the event was successfully received
     */
    boolean internalReceive(Stream<JrubyEventExtLibrary.RubyEvent> events);

    /**
     *
     * @return true if the input is running
     */
    boolean isRunning();
}
