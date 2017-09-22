package org.logstash.plugin;

import org.junit.Test;
import org.logstash.Event;

import java.util.concurrent.SynchronousQueue;

import static org.junit.Assert.assertEquals;

public class TaskTest {
    SynchronousQueue<Event> queue = new SynchronousQueue<>();

    private void enqueue(Event event) {
        try {
            queue.put(event);
        } catch (InterruptedException e) {
            // give up and continue
        }
    }

    @Test
    public void testWorkflow() throws Exception {
        InputTask task = new InputTask(new Generator(), (events) -> events.forEach(this::enqueue));
        task.start();
        Event event = queue.take();
        assertEquals(1L, event.getField("value"));
        task.shutdown();

    }

}