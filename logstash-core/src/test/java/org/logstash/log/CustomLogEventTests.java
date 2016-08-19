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

public class CustomLogEventTests {
    private static final ObjectMapper mapper = new ObjectMapper();
    private static final String CONFIG = "log4j2-test1.xml";
    private ListAppender appender;

    @ClassRule
    public static LoggerContextRule CTX = new LoggerContextRule(CONFIG, StructuredMessageContextSelector.class);


    @Test
    public void testPatternLayout() {
        appender = CTX.getListAppender("EventLogger").clear();
        Logger logger = LogManager.getLogger("EventLogger");
        logger.info("cool");
        logger.warn("hello");
        List<String> messages = appender.getMessages();
        assertEquals("[INFO][EventLogger] cool", messages.get(0));
        assertEquals("[WARN][EventLogger] hello", messages.get(1));
    }

    @Test
    @SuppressWarnings("unchecked")
    public void testJSONLayout() throws Exception {
        appender = CTX.getListAppender("JSONEventLogger").clear();
        Logger logger = LogManager.getLogger("JSONEventLogger");
        logger.info("simple message");
        logger.warn("complex message", Collections.singletonMap("foo", "bar"));

        List<String> messages = appender.getMessages();

        Map<String, Object> firstMessage = mapper.readValue(messages.get(0), Map.class);

        assertEquals(5, firstMessage.size());
        assertEquals("INFO", firstMessage.get("level"));
        assertEquals("JSONEventLogger", firstMessage.get("loggerName"));
        assertEquals("main", firstMessage.get("thread"));
        assertEquals(Collections.singletonMap("message", "simple message"), firstMessage.get("logEvent"));

        Map<String, Object> secondMessage = mapper.readValue(messages.get(1), Map.class);

        assertEquals(5, secondMessage.size());
        assertEquals("WARN", secondMessage.get("level"));
        assertEquals("JSONEventLogger", secondMessage.get("loggerName"));
        assertEquals("main", secondMessage.get("thread"));
        Map<String, Object> logEvent = new HashMap<>();
        logEvent.put("message", "complex message");
        logEvent.put("foo", "bar");
        assertEquals(logEvent, secondMessage.get("logEvent"));
    }
}
