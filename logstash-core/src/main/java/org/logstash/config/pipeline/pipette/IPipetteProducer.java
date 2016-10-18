package org.logstash.config.pipeline.pipette;

/**
 * Created by andrewvc on 9/30/16.
 */
public interface IPipetteProducer {
    void start() throws PipetteExecutionException;

    void stop();

    void onEvents(PipetteSourceEmitter sourceEmitter);
}
