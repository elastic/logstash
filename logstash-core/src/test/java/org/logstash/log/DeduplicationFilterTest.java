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
import org.junit.Test;

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
}
