package org.logstash.plugin;

import org.junit.Test;
import org.logstash.Event;

import java.util.Collection;
import java.util.LinkedList;
import java.util.function.Consumer;

import static org.junit.Assert.assertEquals;

public class PluginIntegrationTest {
    private Collection<Collection<Event>> batches = new LinkedList<>();

    static Collection<Event> generateEvents(int count) {
        Collection<Event> events = new LinkedList<>();
        for (int i = 0; i < count; i++) {
            Event event = new Event();
            event.setField("message", "hello world");
            event.setField("i", i);
            events.add(event);
        }
        return events;
    }

    @Test
    public void testInput() {
        Input i = new TestInput();
        i.run((events) -> batches.add(events));
        assertEquals(batches.size(), 1);
        for (Collection<Event> events : batches) {
            assertEquals(events.size(), 10);
        }
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
        public Collection<Event> process(Collection<Event> events) {
            for (Event e : events) {
                e.setField("visited", "testFilter");
            }
            return null;
        }
    }

}
