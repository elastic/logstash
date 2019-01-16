package org.logstash.plugins.outputs;

import co.elastic.logstash.api.Event;
import com.fasterxml.jackson.core.JsonProcessingException;
import org.junit.Test;
import org.logstash.plugins.ConfigurationImpl;
import org.logstash.plugins.TestContext;
import org.logstash.plugins.TestPluginFactory;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.logstash.ObjectMappers.JSON_MAPPER;

public class StdoutTest {
    private static final String ID = "stdout_test_id";
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
        Stdout stdout = new Stdout(ID, new ConfigurationImpl(Collections.emptyMap(), new TestPluginFactory()),
                new TestContext(), dummyOutputStream);
        stdout.output(getTestEvents());
        stdout.stop();

        assertFalse(streamWasClosed);
    }

    @Test
    public void testEvents() throws JsonProcessingException {
        StringBuilder expectedOutput = new StringBuilder();
        Collection<Event> testEvents = getTestEvents();
        for (Event e : testEvents) {
            expectedOutput.append(String.format(JSON_MAPPER.writeValueAsString(e.getData()) + "%n"));
        }

        OutputStream dummyOutputStream = new ByteArrayOutputStream(0);
        Stdout stdout = new Stdout(ID, new ConfigurationImpl(Collections.emptyMap(), new TestPluginFactory()),
                new TestContext(), dummyOutputStream);
        stdout.output(testEvents);
        stdout.stop();

        assertEquals(expectedOutput.toString(), dummyOutputStream.toString());
    }

    private static Collection<Event> getTestEvents() {
        org.logstash.Event e1 = new org.logstash.Event();
        e1.setField("myField", "event1");
        org.logstash.Event e2 = new org.logstash.Event();
        e2.setField("myField", "event2");
        org.logstash.Event e3 = new org.logstash.Event();
        e3.setField("myField", "event3");
        return Arrays.asList(e1, e2, e3);
    }
}
