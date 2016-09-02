package org.logstash.config.pipeline.pipette;

import org.logstash.Event;

import java.util.List;

/**
 * Created by andrewvc on 10/11/16.
 */
public interface PipetteSourceEmitter {
    void emit(List<Event> events) throws PipetteExecutionException;
}
