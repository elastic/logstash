package org.logstash.plugin;

import org.junit.Test;
import org.logstash.Event;

import java.util.Collection;
import java.util.Collections;
import java.util.LinkedList;
import java.util.function.Consumer;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;

public class InputTest {
    private Collection<Collection<Event>> batches = new LinkedList<>();
    private int batchCount = Util.random.nextInt(10) + 1;

    @Test
    public void testInput() {
        Input i = new TestInput();
        i.run(batches::add);
        assertEquals(batchCount, batches.size());
        for (Collection<Event> events : batches) {
            assertFalse(events.isEmpty());
        }
    }

    private class TestInput implements Input {
        @Override
        public void run(Consumer<Collection<Event>> consumer) {
            for (int b = 0; b < batchCount; b++) {
                int eventCountPerBatch = Util.random.nextInt(100) + 1;
                Collection<Event> events = new LinkedList<>();
                for (int i = 0; i < eventCountPerBatch; i++) {
                    Event e = new Event();
                    e.setField("message", "hello world");
                    e.setField("i", i);
                    e.setField("b", b);
                    events.add(e);
                }
                consumer.accept(Collections.unmodifiableCollection(events));
            }
        }
    }
}
