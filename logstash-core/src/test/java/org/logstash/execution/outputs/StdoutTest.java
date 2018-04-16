package org.logstash.execution.outputs;

import com.fasterxml.jackson.core.JsonProcessingException;
import org.junit.Test;
import org.logstash.Event;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.Arrays;
import java.util.Collection;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;

public class StdoutTest {
    private static boolean streamWasClosed = false;

    /**
     * Verifies that the stdout output is reloadable because it does not close the underlying
     * output stream which, outside of test cases, is always {@link java.lang.System#out}.
     */
    @Test
    public void testUnderlyingStreamIsNotClosed() {
        OutputStream dummyOutputStream = new ByteArrayOutputStream(0) {
            @Override
            public void close() throws IOException {
                streamWasClosed = true;
                super.close();
            }
        };
        Stdout stdout = new Stdout(null, null, dummyOutputStream);
        stdout.output(getTestEvents());
        stdout.stop();

        assertFalse(streamWasClosed);
    }

    @Test
    public void testEvents() throws JsonProcessingException {
        StringBuilder expectedOutput = new StringBuilder();
        Collection<Event> testEvents = getTestEvents();
        for (Event e : testEvents) {
            expectedOutput.append(String.format(e.toJson() + "%n"));
        }

        OutputStream dummyOutputStream = new ByteArrayOutputStream(0);
        Stdout stdout = new Stdout(null, null, dummyOutputStream);
        stdout.output(testEvents);
        stdout.stop();

        assertEquals(expectedOutput.toString(), dummyOutputStream.toString());
    }

    private static Collection<Event> getTestEvents() {
        Event e1 = new Event();
        e1.setField("myField", "event1");
        Event e2 = new Event();
        e2.setField("myField", "event2");
        Event e3 = new Event();
        e3.setField("myField", "event3");
        return Arrays.asList(new Event[]{e1, e2, e3});
    }
}
