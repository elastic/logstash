package org.logstash.config.pipeline.pipette;


import org.logstash.Event;
import org.logstash.config.pipeline.PipelineRunnerObserver;

import java.util.List;

/**
 * Created by andrewvc on 9/30/16.
 */
public class Pipette {
    public final IPipetteSource source;
    public final IPipetteProcessor processor;
    private final String name;
    private final PipelineRunnerObserver observer;


    private final class OnWriteEmitter implements PipetteSourceEmitter {
        @Override
        public void emit(List<Event> events) throws PipetteExecutionException {
            process(events);
        }
    }

    public Pipette(String name, IPipetteSource source, IPipetteProcessor processor, PipelineRunnerObserver observer) {
        this.name = name;
        this.source = source;
        this.processor = processor;
        this.observer = observer;
        this.source.onEvents(new OnWriteEmitter());
    }


    public Pipette(String name, IPipetteSource source, IPipetteProcessor processor) {
        this(name, source, processor, null);
    }

    public void start() throws PipetteExecutionException {
        source.start();
    }

    private void process(List<Event> events) throws PipetteExecutionException {
        processor.process(events);
    }

    public void stop() throws PipetteExecutionException {
        source.stop();
        processor.stop();
    }

    public String toString() {
        return name;
    }

}
