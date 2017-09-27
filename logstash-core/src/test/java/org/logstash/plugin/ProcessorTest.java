package org.logstash.plugin;

import org.junit.Test;
import org.logstash.Event;
import org.logstash.TestUtil;

import java.util.Collection;
import java.util.Collections;
import java.util.LinkedList;

import static org.junit.Assert.assertEquals;

public class ProcessorTest {
    static Collection<Event> generateEvents(int count) {
        Collection<Event> events = new LinkedList<>();
        for (long i = 0; i < count; i++) {
            Event event = new Event();
            event.setField("message", "hello world");
            event.setField("i", i);
            events.add(event);
        }
        return Collections.unmodifiableCollection(events);
    }

    @Test
    public void testFilter() {
        processor.process(events);

        long i = 0;
        for (Event event : events) {
            assertEquals(i, event.getField("i"));
            i++;
        }
    }

    private Processor processor = new TestFilter();
    private int eventCount = TestUtil.random.nextInt(100);
    private Collection<Event> events = generateEvents(eventCount);

    private class TestFilter implements Processor {

        @Override
        public void process(Collection<Event> events) {
            for (Event e : events) {
                e.setField("visited", "testFilter");
            }
        }
    }
}
