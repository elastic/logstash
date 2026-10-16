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

package org.logstash.log;

import org.apache.logging.log4j.Level;
import org.apache.logging.log4j.core.Filter;
import org.apache.logging.log4j.core.LogEvent;
import org.apache.logging.log4j.core.impl.Log4jLogEvent;
import org.apache.logging.log4j.message.SimpleMessage;
import org.apache.logging.log4j.status.StatusData;
import org.apache.logging.log4j.status.StatusListener;
import org.apache.logging.log4j.status.StatusLogger;
import org.junit.Test;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import static org.hamcrest.MatcherAssert.assertThat;

import static org.hamcrest.Matchers.containsString;
import static org.junit.Assert.assertEquals;

public class DeduplicationFilterTest {

    @Test
    public void givenAStringAtInfoLevelWhenAppearsFirstTimeThenIsForwarded() {
        final DeduplicationFilter filter = DeduplicationFilter.createFilter(
                DeduplicationFilter.DEFAULT_FALSE_POSITIVE_PROBABILITY);

        final Filter.Result result = filter.filter(logEvent(Level.INFO, "duplicate me"));

        assertEquals(Filter.Result.NEUTRAL, result);
    }

    @Test
    public void givenAStringAtWarnLevelWhenAppearsMultipleTimesThenIsDenied() {
        final DeduplicationFilter filter = DeduplicationFilter.createFilter(
                DeduplicationFilter.DEFAULT_FALSE_POSITIVE_PROBABILITY);

        filter.filter(logEvent(Level.WARN, "same line"));
        final Filter.Result result = filter.filter(logEvent(Level.WARN, "same line"));

        assertEquals(Filter.Result.DENY, result);
    }

    @Test
    public void givenAStringWhenAppearsAtDifferentLevelThenIsForwarded() {
        final DeduplicationFilter filter = DeduplicationFilter.createFilter(
                DeduplicationFilter.DEFAULT_FALSE_POSITIVE_PROBABILITY);

        filter.filter(logEvent(Level.INFO, "shared text"));
        final Filter.Result result = filter.filter(logEvent(Level.ERROR, "shared text"));

        assertEquals(Filter.Result.NEUTRAL, result);
    }

    @Test
    public void invalidFalsePositiveProbabilityFallsBackToDefault() {
        assertEquals(
                DeduplicationFilter.DEFAULT_FALSE_POSITIVE_PROBABILITY,
                DeduplicationFilter.resolveFalsePositiveProbability(0.0),
                0.0
        );
        assertEquals(
                DeduplicationFilter.DEFAULT_FALSE_POSITIVE_PROBABILITY,
                DeduplicationFilter.resolveFalsePositiveProbability(1.0),
                0.0
        );
        assertEquals(
                DeduplicationFilter.DEFAULT_FALSE_POSITIVE_PROBABILITY,
                DeduplicationFilter.resolveFalsePositiveProbability(-0.5),
                0.0
        );
    }

    @Test
    public void validFalsePositiveProbabilityIsPreserved() {
        assertEquals(0.001, DeduplicationFilter.resolveFalsePositiveProbability(0.001), 0.0);
    }

    private static LogEvent logEvent(final Level level, final String message) {
        return Log4jLogEvent.newBuilder()
                .setLevel(level)
                .setMessage(new SimpleMessage(message))
                .build();
    }
    
    private static class SpyListener implements StatusListener {
        
        private final List<StatusData> spiedMessages = new ArrayList<>();
        
        @Override
        public void log(StatusData data) {
            spiedMessages.add(data);
        }

        @Override
        public Level getStatusLevel() {
            return Level.WARN;
        }

        @Override
        public void close() throws IOException {

        }
    }
    
    @Test
    public void givenFalsePositiveProbabilitySetToValueOutsideExpectedRangeThenOverrideToDefaultAndLog() throws IOException {
        // setup
        try (SpyListener loggerSpy = new SpyListener()) {
            StatusLogger.getLogger().registerListener(loggerSpy);

            // Exercise
            DeduplicationFilter.resolveFalsePositiveProbability(1.0);

            // Verify
            final StatusData data = loggerSpy.spiedMessages.get(0);
            assertEquals(Level.WARN, data.getLevel());
            assertThat(data.getMessage().getFormattedMessage(), containsString("falsePositiveProbability is expected to be in the range (0, 5%] but was"));
            
            // teardown
            StatusLogger.getLogger().removeListener(loggerSpy);
        }
    }
}
