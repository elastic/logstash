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

package org.logstash.common;

import org.apache.logging.log4j.core.test.appender.ListAppender;
import org.apache.logging.log4j.core.test.junit.LoggerContextRule;
import org.junit.Before;
import org.junit.ClassRule;
import org.junit.Test;

import java.util.List;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThrows;
import static org.junit.Assert.assertTrue;

/**
 * Verifies that BufferedTokenizer logs a WARN message with the dropped byte count whenever
 * buffered data is silently discarded due to the sizeLimit being exceeded.
 *
 * Two trigger points are tested:
 *  1. When a separator arrives after a sequence of dropped fragments (recovery in append).
 *  2. When flush() is called while dropped data is outstanding.
 */
public final class BufferedTokenizerDroppedDataLoggingTest {

    private static final String CONFIG = "log4j2-test1.xml";

    @ClassRule
    public static LoggerContextRule CTX = new LoggerContextRule(CONFIG);

    private ListAppender appender;
    private BufferedTokenizer sut;

    @Before
    public void setUp() {
        appender = CTX.getListAppender("EventLogger").clear();
        sut = new BufferedTokenizer("\n", 10);
    }

    @Test
    public void givenDroppedFragmentsWhenSeparatorArrivesInAppendThenWarnIsLoggedWithDroppedByteCount() {
        // "01234567890" (11 chars) — NOT dropped because lastFragmentSize starts at 0
        sut.extract("01234567890");

        // "AAAAA" (5 chars, no sep) — dropped: lastFragmentSize(11) > sizeLimit(10)
        sut.extract("AAAAA");

        // "BBBBB" (5 chars, no sep) — dropped: still 11 > 10
        sut.extract("BBBBB");

        // No warn yet — separator hasn't arrived
        assertTrue("No warning should be emitted before a separator is seen",
                warnMessages().stream().noneMatch(m -> m.contains("dropped")));

        // "\nCC" contains a separator → recovery triggers the warn with 10 dropped bytes
        sut.extract("\nCC");

        assertEquals(1, warnMessages().size());
        assertThat("Warning must report 10 dropped bytes (AAAAA + BBBBB)", warnMessages().getFirst(), containsString("dropped 10 bytes"));
    }

    @Test
    public void givenMultipleBatchesOfDroppedDataWhenSeparatorArrivesRepeatedly_ThenEachBatchIsLoggedSeparately() {
        // First overrun: 11 chars, no sep → accumulated (lastFragmentSize = 11)
        sut.extract("01234567890");

        // Drop 3 bytes
        sut.extract("AAA");
        // Recovery: separator seen → warn("3 bytes dropped")
        sut.extract("\n");

        assertEquals(1, warnMessages().size());
        assertThat("First warn should report 3 dropped bytes", warnMessages().getFirst(), containsString("dropped 3 bytes"));

        // Start a new overrun: 11 chars again → accumulated on top of existing content
        sut.extract("01234567890");
        // Drop 7 bytes
        sut.extract("BBBBBBB");
        // Recovery: separator seen → warn("7 bytes dropped")
        sut.extract("\n");

        assertEquals(2, warnMessages().size());
        assertThat("Second warn should report 7 dropped bytes", warnMessages().getLast(), containsString("dropped 7 bytes"));
    }
    
    @Test
    public void givenDroppedFragmentsWhenFlushIsInvokedThenWarnIsLoggedWithDroppedByteCountBeforeThrowing() {
        // "01234567890" (11 chars) — accumulated, lastFragmentSize = 11
        sut.extract("01234567890");

        // Drop 4 bytes
        sut.extract("CCCC");
        // Drop 6 bytes
        sut.extract("DDDDDD");

        // No warn yet — separator hasn't arrived and flush not called
        assertTrue("No warning before flush", warnMessages().stream().noneMatch(m -> m.contains("dropped")));

        // flush() must warn about dropped data then throw for the overrun partial token
        assertThrows(IllegalStateException.class, () -> sut.flush());

        assertEquals(1, warnMessages().size());
        assertThat("Warning must report 10 dropped bytes (CCCC + DDDDDD)", warnMessages().getFirst(), containsString("dropped 10 bytes"));
    }

    @Test
    public void givenDroppedFragmentsWhenFlushIsInvokedThenWarnPrecedesTheException() {
        sut.extract("01234567890"); // accumulated, lastFragmentSize = 11
        sut.extract("EEE");        // dropped (3 bytes)

        assertThrows(IllegalStateException.class, () -> sut.flush());

        // The warn must have been emitted (before the exception propagated)
        assertEquals(1, warnMessages().size());
        assertThat("Dropped-data warn must be logged even when flush throws", warnMessages().getFirst(), containsString("dropped 3 bytes"));
    }

    @Test
    public void givenNoDroppedDataWhenFlushIsInvokedThenNoWarnIsLogged() {
        sut.extract("short");
        sut.flush();

        assertTrue("No dropped-data warn should appear when nothing was dropped",
                warnMessages().stream().noneMatch(m -> m.contains("dropped")));
    }

    @Test
    public void givenNoDroppedDataWhenSeparatorArrivesNoWarnIsLogged() {
        sut.extract("hello\nworld");

        assertTrue("No dropped-data warn should appear for normal tokenization",
                warnMessages().stream().noneMatch(m -> m.contains("dropped")));
    }

    private List<String> warnMessages() {
        return appender.getMessages();
    }
}
