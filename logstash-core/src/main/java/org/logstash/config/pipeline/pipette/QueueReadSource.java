package org.logstash.config.pipeline.pipette;

import org.logstash.Event;

import java.util.List;
import java.util.concurrent.BlockingQueue;

/**
 * Created by andrewvc on 10/11/16.
 */
public class QueueReadSource implements IPipetteSource {
    private final BlockingQueue<List<Event>> queue;
    private volatile boolean running;
    private PipetteSourceEmitter onEventsReader;

    public QueueReadSource(BlockingQueue<List<Event>> queue) {
        this.queue = queue;
        this.running = true;
    }

    @Override
    public void start() throws PipetteExecutionException {
        while (this.running) {
            List<Event> events = null;
            try {
                events = queue.take();
            } catch (InterruptedException e) {
                throw new PipetteExecutionException("Unexpected Interruption!", e);
            }

            onEventsReader.emit(events);
        }
    }

    @Override
    public void stop() {
        this.running = false;
    }

    @Override
    public void onEvents(PipetteSourceEmitter onEvents) {
       this.onEventsReader = onEvents;
    }


}
