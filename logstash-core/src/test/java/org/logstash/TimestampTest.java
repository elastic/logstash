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

import org.joda.time.DateTime;
import org.joda.time.DateTimeZone;
import org.junit.Assert;
import org.junit.Test;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.util.Locale;

import static org.junit.Assert.*;

public class TimestampTest {


    static final Clock OFFSET_CLOCK = Clock.systemUTC().withZone(ZoneId.of("-08:00"));
    static final Locale LOCALE = Locale.US;

    @Test
    @SuppressWarnings({"deprecation"})
    public void testCircularIso8601() throws Exception {
        Timestamp t1 = new Timestamp();
        Timestamp t2 = new Timestamp(t1.toString());
        //noinspection deprecation
        assertEquals(t1.getTime(), t2.getTime());
        assertEquals(t1.toInstant(), t2.toInstant());
    }

    @Test
    public void testToString() throws Exception {
        Timestamp t = new Timestamp("2014-09-23T12:34:56.789012345-0800", OFFSET_CLOCK, LOCALE);
        assertEquals("2014-09-23T20:34:56.789012345Z", t.toString());
    }

    @Test
    public void testToStringNoNanos() throws Exception {
        Timestamp t = new Timestamp("2014-09-23T12:34:56.000000000-0800", OFFSET_CLOCK, LOCALE);
        assertEquals("2014-09-23T20:34:56.000Z", t.toString());
    }

    @Test
    public void testParsingDateTimeNoOffset() throws Exception {
        final Timestamp t = new Timestamp("2014-09-23T12:34:56.789012345", OFFSET_CLOCK, LOCALE);
        assertEquals("2014-09-23T20:34:56.789012345Z", t.toString());
    }
    @Test
    public void testParsingDateNoOffset() throws Exception {
        final Timestamp t = new Timestamp("2014-09-23", OFFSET_CLOCK, LOCALE);
        assertEquals("2014-09-23T08:00:00.000Z", t.toString());
    }

    @Test
    public void testParsingDateWithOffset() throws Exception {
        final Timestamp t = new Timestamp("2014-09-23-08:00", OFFSET_CLOCK, LOCALE);
        assertEquals("2014-09-23T08:00:00.000Z", t.toString());
    }

    @Test
    public void testParsingDateTimeWithZOffset() throws Exception {
        final Timestamp t = new Timestamp("2014-09-23T13:49:52.987654321Z", OFFSET_CLOCK, LOCALE);
        assertEquals("2014-09-23T13:49:52.987654321Z", t.toString());
    }

    @Test
    public void testParsingDateTimeWithCommaDecimalStyleLocale() throws Exception {
        final Locale germanLocale = Locale.GERMANY;
        final Clock germanClock = Clock.systemUTC().withZone(ZoneId.of("+02:00")); // DST doesn't matter

        // comma-decimal
        final Timestamp t1 = new Timestamp("2014-09-23T13:49:52,987654321Z", germanClock, germanLocale);
        assertEquals("2014-09-23T13:49:52.987654321Z", t1.toString());

        // fallback to stop-decimal
        final Timestamp t2 = new Timestamp("2014-09-23T13:49:52.987654321Z", germanClock, germanLocale);
        assertEquals("2014-09-23T13:49:52.987654321Z", t2.toString());
    }

    // Timestamp should always be in a UTC representation
    // TODO: remove spec, since `Instant` is UTC by default.
    @Test
    @SuppressWarnings({"deprecation"})
    public void testUTC() throws Exception {
        Timestamp t;

        t = new Timestamp();
        //noinspection deprecation
        assertEquals(DateTimeZone.UTC, t.getTime().getZone());

        t = new Timestamp("2014-09-23T00:00:00-0800");
        //noinspection deprecation
        assertEquals(DateTimeZone.UTC, t.getTime().getZone());

        t = new Timestamp("2014-09-23T08:00:00.000Z");
        //noinspection deprecation
        assertEquals(DateTimeZone.UTC, t.getTime().getZone());

        long ms = DateTime.now(DateTimeZone.forID("EST")).getMillis();
        t = new Timestamp(ms);
        //noinspection deprecation
        assertEquals(DateTimeZone.UTC, t.getTime().getZone());
    }

    @Test
    public void testMicroseconds() {
        Instant i = Instant.now();
        Timestamp t1 = new Timestamp(i.toEpochMilli());
        long usec = t1.usec();

        // since our Timestamp was created with epoch millis, it cannot be more precise.
        Assert.assertEquals(i.getNano() / 1_000_000, usec / 1_000);
    }

    @Test
    public void testEpochMillis() {
        Instant i = Instant.now();
        Timestamp t1 = new Timestamp(i.toEpochMilli());
        long millis = t1.toEpochMilli();
        Assert.assertEquals(i.toEpochMilli(), millis);
    }

    @Test
    public void testNanoPrecision() {
        final String input = "2021-04-02T00:28:17.987654321Z";
        final Timestamp t1 = new Timestamp(input);

        assertEquals(987654321, t1.toInstant().getNano());
    }
}
