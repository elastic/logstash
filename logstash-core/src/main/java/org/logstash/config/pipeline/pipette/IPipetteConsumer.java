package org.logstash.config.pipeline.pipette;

import org.logstash.Event;

import java.util.List;

/**
 * Created by andrewvc on 9/30/16.
 */
public interface IPipetteConsumer {
   void process(List<Event> events) throws PipetteExecutionException;
   void stop() throws PipetteExecutionException;
}
