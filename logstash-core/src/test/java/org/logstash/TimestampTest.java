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

import java.time.Instant;

import static org.junit.Assert.*;

public class TimestampTest {


    @Test
    public void testCircularIso8601() throws Exception {
        Timestamp t1 = new Timestamp();
        Timestamp t2 = new Timestamp(t1.toString());
        assertEquals(t1.getTime(), t2.getTime());
    }

    @Test
    public void testToIso8601() throws Exception {
        Timestamp t = new Timestamp("2014-09-23T00:00:00-0800");
        assertEquals("2014-09-23T08:00:00.000Z", t.toString());
    }

    // Timestamp should always be in a UTC representation
    @Test
    public void testUTC() throws Exception {
        Timestamp t;

        t = new Timestamp();
        assertEquals(DateTimeZone.UTC, t.getTime().getZone());

        t = new Timestamp("2014-09-23T00:00:00-0800");
        assertEquals(DateTimeZone.UTC, t.getTime().getZone());

        t = new Timestamp("2014-09-23T08:00:00.000Z");
        assertEquals(DateTimeZone.UTC, t.getTime().getZone());

        long ms = DateTime.now(DateTimeZone.forID("EST")).getMillis();
        t = new Timestamp(ms);
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

}
