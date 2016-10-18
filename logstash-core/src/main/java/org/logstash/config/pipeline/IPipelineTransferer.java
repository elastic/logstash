package org.logstash.config.pipeline;

import org.logstash.config.pipeline.pipette.IPipetteConsumer;
import org.logstash.config.pipeline.pipette.IPipetteProducer;

/**
 * Created by andrewvc on 10/18/16.
 */
public interface IPipelineTransferer {
    void start();
    IPipetteConsumer makeConsumer();
    IPipetteProducer makeProducer();
    void stop();
}
