package org.logstash.config.pipeline.pipette;

import org.logstash.Event;

import java.util.List;
import java.util.concurrent.BlockingQueue;

/**
 * Created by andrewvc on 10/11/16.
 */
public class QueueWriteConsumer implements IPipetteConsumer {
    private final BlockingQueue<List<Event>> queue;

    public QueueWriteConsumer(BlockingQueue<List<Event>> queue) {
        this.queue = queue;
    }

    @Override
    public void process(List<Event> events) throws PipetteExecutionException {
        try {
            this.queue.put(events);
        } catch (InterruptedException e) {
            throw new PipetteExecutionException("Unexpected interruption!", e);
        }
    }

    @Override
    public void stop() throws PipetteExecutionException {

    }
}
