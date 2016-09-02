package org.logstash.config.pipeline.pipette;

import org.logstash.Event;

import java.util.List;

/**
 * Created by andrewvc on 9/30/16.
 */
public interface IPipetteProcessor {
    public void process(List<Event> events) throws PipetteExecutionException;
    public void stop() throws PipetteExecutionException;
}
