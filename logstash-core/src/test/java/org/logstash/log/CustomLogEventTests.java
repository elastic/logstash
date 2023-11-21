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

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.core.JsonProcessingException;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.junit.LoggerContextRule;
import org.apache.logging.log4j.test.appender.ListAppender;
import org.jruby.RubyHash;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.ClassRule;
import org.junit.Test;
import org.logstash.ObjectMappers;
import org.logstash.RubyUtil;

import static junit.framework.TestCase.assertFalse;
import static junit.framework.TestCase.assertEquals;
import static junit.framework.TestCase.assertNotNull;

public class CustomLogEventTests {
    private static final String CONFIG = "log4j2-test1.xml";

    @ClassRule
    public static LoggerContextRule CTX = new LoggerContextRule(CONFIG);

    @Test
    public void testPatternLayout() {
        ListAppender appender = CTX.getListAppender("EventLogger").clear();
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
        ListAppender appender = CTX.getListAppender("JSONEventLogger").clear();
        Logger logger = LogManager.getLogger("JSONEventLogger");
        logger.info("simple message");
        logger.warn("complex message", Collections.singletonMap("foo", "bar"));
        logger.error("my name is: {}", "foo");
        logger.error("here is a map: {}", Collections.singletonMap(2, 5));
        logger.warn("ignored params {}", 4, 6, 8);

        List<String> messages = appender.getMessages();

        Map<String, Object> firstMessage =
            ObjectMappers.JSON_MAPPER.readValue(messages.get(0), Map.class);

        assertEquals(5, firstMessage.size());
        assertEquals("INFO", firstMessage.get("level"));
        assertEquals("JSONEventLogger", firstMessage.get("loggerName"));
        assertNotNull(firstMessage.get("thread"));
        assertEquals(Collections.singletonMap("message", "simple message"), firstMessage.get("logEvent"));

        Map<String, Object> secondMessage =
            ObjectMappers.JSON_MAPPER.readValue(messages.get(1), Map.class);

        assertEquals(5, secondMessage.size());
        assertEquals("WARN", secondMessage.get("level"));
        assertEquals("JSONEventLogger", secondMessage.get("loggerName"));
        assertNotNull(secondMessage.get("thread"));
        Map<String, Object> logEvent = new HashMap<>();
        logEvent.put("message", "complex message");
        logEvent.put("foo", "bar");
        assertEquals(logEvent, secondMessage.get("logEvent"));

        Map<String, Object> thirdMessage =
            ObjectMappers.JSON_MAPPER.readValue(messages.get(2), Map.class);
        assertEquals(5, thirdMessage.size());
        logEvent = Collections.singletonMap("message", "my name is: foo");
        assertEquals(logEvent, thirdMessage.get("logEvent"));

        Map<String, Object> fourthMessage =
            ObjectMappers.JSON_MAPPER.readValue(messages.get(3), Map.class);
        assertEquals(5, fourthMessage.size());
        logEvent = new HashMap<>();
        logEvent.put("message", "here is a map: {}");
        logEvent.put("2", 5);
        assertEquals(logEvent, fourthMessage.get("logEvent"));

        Map<String, Object> fifthMessage =
            ObjectMappers.JSON_MAPPER.readValue(messages.get(4), Map.class);
        assertEquals(5, fifthMessage.size());
        logEvent = Collections.singletonMap("message", "ignored params 4");
        assertEquals(logEvent, fifthMessage.get("logEvent"));
    }

    @Test
    @SuppressWarnings("unchecked")
    public void testJSONLayoutWithRubyObjectArgument() throws JsonProcessingException {
        final ListAppender appender = CTX.getListAppender("JSONEventLogger").clear();
        final Logger logger = LogManager.getLogger("JSONEventLogger");

        final IRubyObject fooRubyObject = RubyUtil.RUBY.evalScriptlet("Class.new do def initialize\n @foo = true\n end\n def to_s\n 'foo_value'\n end end.new");
        final Map<Object, Object> arguments = RubyHash.newHash(RubyUtil.RUBY);
        arguments.put("foo", fooRubyObject);
        arguments.put("bar", "bar_value");
        arguments.put("one", 1);

        final Map<Object, Object> mapArgValue = RubyHash.newHash(RubyUtil.RUBY);
        mapArgValue.put("first", 1);
        mapArgValue.put("second", 2);
        arguments.put("map", mapArgValue);

        logger.error("Error with hash: {}", arguments);

        final List<String> loggedMessages = appender.getMessages();
        assertFalse(loggedMessages.isEmpty());
        assertFalse(loggedMessages.get(0).isEmpty());

        final Map<String, Object> message =  ObjectMappers.JSON_MAPPER.readValue(loggedMessages.get(0), Map.class);
        final Map<String, Object> logEvent = (Map<String, Object>) message.get("logEvent");

        assertEquals("Error with hash: {}", logEvent.get("message"));
        assertEquals("foo_value", logEvent.get("foo"));
        assertEquals("bar_value", logEvent.get("bar"));
        assertEquals(1, logEvent.get("one"));

        final Map<String, Object> logEventMapValue = (Map<String, Object>) logEvent.get("map");
        assertEquals(1, logEventMapValue.get("first"));
        assertEquals(2, logEventMapValue.get("second"));
    }
}
