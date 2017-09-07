package org.logstash.plugin;

import org.junit.Test;
import org.logstash.Event;

import java.util.Collection;
import java.util.LinkedList;
import java.util.function.Consumer;

import static org.junit.Assert.assertEquals;

public class PluginIntegrationTest {
    private Collection<BatchImpl> batches = new LinkedList<>();

    @Test
    public void testInput() {
        Input i = new TestInput();
        i.run((events) -> batches.add(new BatchImpl(events)));

        assertEquals(batches.size(), 1);
        for (BatchImpl batch : batches) {
            assertEquals(batch.size(), 10);
        }
    }

    private BatchImpl generateBatch(int count) {
        Collection<Event> events = new LinkedList<>();
        for (int i = 0; i < count; i++) {
            Event event = new Event();
            event.setField("message", "hello world");
            event.setField("i", i);
            events.add(event);
        }
        return new BatchImpl(events);
    }

    @Test
    public void testProcessorRemove() {
        int count = 10;
        BatchImpl batch = generateBatch(count);

        assertEquals(batch.size(), count);

        Processor p = (b) -> b.remove(b.iterator().next());
        p.process(batch);

        assertEquals(batch.size(), count - 1);
    }

    @Test
    public void testBatchAdd() {
        int count = 10;
        BatchImpl batch = generateBatch(count);

        assertEquals(batch.size(), count);

        Processor p = (b) -> b.add(new Event());
        p.process(batch);

        assertEquals(batch.size(), count + 1);
    }

    private class TestInput implements Input {
        @Override
        public void run(Consumer<Collection<Event>> consumer) {
            Collection<Event> events = new LinkedList<>();

            for (int i = 0; i < 10; i++) {
                Event e = new Event();
                e.setField("message", "hello world");
                e.setField("i", i);
                events.add(e);
            }

            consumer.accept(events);
        }
    }

    private class TestFilter implements Processor {
        @Override
        public void process(ProcessorBatch batch) {
            for (Event e : batch) {
                e.setField("visited", "testFilter");
            }
        }
    }

}
