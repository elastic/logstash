/*
 * Licensed to Elasticsearch under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.logstash.log;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.junit.LoggerContextRule;
import org.apache.logging.log4j.test.appender.ListAppender;
import org.junit.ClassRule;
import org.junit.Test;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static junit.framework.TestCase.assertEquals;
import static junit.framework.TestCase.assertNotNull;

public class CustomLogEventTests {
    private static final ObjectMapper mapper = new ObjectMapper();
    private static final String CONFIG = "log4j2-test1.xml";
    private ListAppender appender;

    @ClassRule
    public static LoggerContextRule CTX = new LoggerContextRule(CONFIG);

    @Test
    public void testPatternLayout() {
        appender = CTX.getListAppender("EventLogger").clear();
        Logger logger = LogManager.getLogger("EventLogger");
        logger.info("simple message");
        logger.warn("complex message", Collections.singletonMap("foo", "bar"));
        logger.error("my name is: {}", "foo");
        logger.error("here is a map: {}. ok?", Collections.singletonMap(2, 5));
        logger.warn("ignored params {}", 4, 6);
        List<String> messages = appender.getMessages();
        assertEquals(5, messages.size());
        assertEquals("[INFO][EventLogger] simple message", messages.get(0));
        assertEquals("[WARN][EventLogger] complex message {foo=bar}", messages.get(1));
        assertEquals("[ERROR][EventLogger] my name is: foo", messages.get(2));
        assertEquals("[ERROR][EventLogger] here is a map: {}. ok? {2=5}", messages.get(3));
        assertEquals("[WARN][EventLogger] ignored params 4", messages.get(4));
    }

    @Test
    @SuppressWarnings("unchecked")
    public void testJSONLayout() throws Exception {
        appender = CTX.getListAppender("JSONEventLogger").clear();
        Logger logger = LogManager.getLogger("JSONEventLogger");
        logger.info("simple message");
        logger.warn("complex message", Collections.singletonMap("foo", "bar"));
        logger.error("my name is: {}", "foo");
        logger.error("here is a map: {}", Collections.singletonMap(2, 5));
        logger.warn("ignored params {}", 4, 6, 8);

        List<String> messages = appender.getMessages();

        Map<String, Object> firstMessage = mapper.readValue(messages.get(0), Map.class);

        assertEquals(5, firstMessage.size());
        assertEquals("INFO", firstMessage.get("level"));
        assertEquals("JSONEventLogger", firstMessage.get("loggerName"));
        assertNotNull(firstMessage.get("thread"));
        assertEquals(Collections.singletonMap("message", "simple message"), firstMessage.get("logEvent"));

        Map<String, Object> secondMessage = mapper.readValue(messages.get(1), Map.class);

        assertEquals(5, secondMessage.size());
        assertEquals("WARN", secondMessage.get("level"));
        assertEquals("JSONEventLogger", secondMessage.get("loggerName"));
        assertNotNull(secondMessage.get("thread"));
        Map<String, Object> logEvent = new HashMap<>();
        logEvent.put("message", "complex message");
        logEvent.put("foo", "bar");
        assertEquals(logEvent, secondMessage.get("logEvent"));

        Map<String, Object> thirdMessage = mapper.readValue(messages.get(2), Map.class);
        assertEquals(5, thirdMessage.size());
        logEvent = Collections.singletonMap("message", "my name is: foo");
        assertEquals(logEvent, thirdMessage.get("logEvent"));

        Map<String, Object> fourthMessage = mapper.readValue(messages.get(3), Map.class);
        assertEquals(5, fourthMessage.size());
        logEvent = new HashMap<>();
        logEvent.put("message", "here is a map: {}");
        logEvent.put("2", 5);
        assertEquals(logEvent, fourthMessage.get("logEvent"));

        Map<String, Object> fifthMessage = mapper.readValue(messages.get(4), Map.class);
        assertEquals(5, fifthMessage.size());
        logEvent = Collections.singletonMap("message", "ignored params 4");
        assertEquals(logEvent, fifthMessage.get("logEvent"));
    }
}
