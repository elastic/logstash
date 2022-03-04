/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.plugins.outputs;

import co.elastic.logstash.api.Event;
import com.fasterxml.jackson.core.JsonProcessingException;
import org.junit.Assert;
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

    @Test
    public void testEventLargerThanBuffer() {
        StringBuilder message = new StringBuilder();
        String repeatedMessage = "foo";
        for (int k = 0; k < (16 * 1024 / repeatedMessage.length()); k++) {
            message.append("foo");
        }

        org.logstash.Event e = new org.logstash.Event();
        e.setField("message", message.toString());

        OutputStream dummyOutputStream = new ByteArrayOutputStream(17 * 1024);
        Stdout stdout = new Stdout(ID, new ConfigurationImpl(Collections.emptyMap(), new TestPluginFactory()),
                new TestContext(), dummyOutputStream);
        stdout.output(Collections.singletonList(e));
        stdout.stop();

        Assert.assertTrue(dummyOutputStream.toString().contains(message.toString()));
    }
}
