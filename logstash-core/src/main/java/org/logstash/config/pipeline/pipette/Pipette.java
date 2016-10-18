package org.logstash.config.pipeline.pipette;


import org.logstash.Event;
import org.logstash.config.pipeline.PipelineRunnerObserver;

import java.util.List;

/**
 * Created by andrewvc on 9/30/16.
 */
public class Pipette {
    public final IPipetteProducer producer;
    public final IPipetteConsumer consumer;
    private final String name;
    private final PipelineRunnerObserver observer;


    private final class OnWriteEmitter implements PipetteSourceEmitter {
        @Override
        public void emit(List<Event> events) throws PipetteExecutionException {
            process(events);
        }
    }

    public Pipette(String name, IPipetteProducer producer, IPipetteConsumer consumer, PipelineRunnerObserver observer) {
        this.name = name;
        this.producer = producer;
        this.consumer = consumer;
        this.observer = observer;
        this.producer.onEvents(new OnWriteEmitter());
    }


    public Pipette(String name, IPipetteProducer producer, IPipetteConsumer consumer) {
        this(name, producer, consumer, null);
    }

    public void start() throws PipetteExecutionException {
        producer.start();
    }

    private void process(List<Event> events) throws PipetteExecutionException {
        consumer.process(events);
    }

    public void stop() throws PipetteExecutionException {
        producer.stop();
        consumer.stop();
    }

    public String toString() {
        return name;
    }

}
