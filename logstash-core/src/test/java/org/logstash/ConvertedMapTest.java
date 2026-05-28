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


package org.logstash;

import org.apache.logging.log4j.core.test.appender.ListAppender;
import org.apache.logging.log4j.core.test.junit.LoggerContextRule;
import org.hamcrest.Matchers;
import org.junit.Assert;
import org.junit.Before;
import org.junit.ClassRule;
import org.junit.Test;

import java.io.NotSerializableException;
import java.io.Serial;
import java.io.Serializable;
import java.util.Map;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.*;
import static org.junit.Assert.assertEquals;

public class ConvertedMapTest {

    private static final String CONFIG = "log4j2-test1.xml";

    @ClassRule
    public static LoggerContextRule CTX = new LoggerContextRule(CONFIG);

    private ListAppender appender;

    @Before
    public void setUp() {
        appender = CTX.getListAppender("EventLogger").clear();
    }
    
    private static class MySerializableClass implements Serializable {
        @Serial
        private static final long serialVersionUID = 6867271638521724011L;

        private final String message;

        private MySerializableClass(String message) {
            this.message = message;
        }
    }

    private static class MyNonSerializableClass {

        private final String message;

        private MyNonSerializableClass(String message) {
            this.message = message;
        }
    }

    @Test
    public void givenKnownClassInstancesWhenEstimateMemoryThenValueIsReturned() {
        ConvertedMap sut = ConvertedMap.newFromMap(Map.of("name", "Pete", "surname", "Mitchell"));
        assertThat("Estimate of know class must return without error", sut.estimateMemory(""), is(greaterThan(10L)));
    }
    
    @Test
    public void givenUnknownSerializableInstanceWhenEstimateSizeThenLogDebugAndReturnValue() {
        ConvertedMap nested = ConvertedMap.newFromMap(Map.of("serializable", "to replace"));
        nested.putInterned("serializable", new MySerializableClass("Mitchell"));
        ConvertedMap sut = ConvertedMap.newFromMap(Map.of("known", "Pete", "nested", nested));
        
        long result = sut.estimateMemory("");

        assertThat("Estimate of unknown serializable class must return without error", result, is(greaterThan(10L)));
        assertEquals(1, appender.getMessages().size());
        String debugMessage = appender.getMessages().getFirst();
        assertThat("Expected log line", debugMessage, containsString("Used Java serialization to estimate ConvertedMap field <[nested][serializable]>"));
        assertThat(debugMessage, containsString("MySerializableClass"));
    }

    @Test
    public void givenUnknownNotSerializableInstanceWhenEstimateSizeThenThrowException() {
        ConvertedMap nested = ConvertedMap.newFromMap(Map.of("notserializable", "to replace"));
        nested.putInterned("notserializable", new MyNonSerializableClass("Mitchell"));
        ConvertedMap sut = ConvertedMap.newFromMap(Map.of("known", "Pete", "nested", nested));

        IllegalArgumentException e = Assert.assertThrows(
                "Expected to throw an error on not serializable instance",
                IllegalArgumentException.class,
                () -> sut.estimateMemory("")
        );
        Throwable wrapped = e.getCause();
        assertThat(wrapped, Matchers.instanceOf(NotSerializableException.class));
        assertThat(e.getMessage(), containsString("Please ensure all objects passed to estimateMemory are of supported types"));
        assertThat(e.getMessage(), containsString("on field <[nested][notserializable]>"));
     }
}