package org.logstash;

import org.joda.time.DateTime;
import org.joda.time.DateTimeZone;
import org.junit.Test;

import static org.junit.Assert.*;

public class TimestampTest {


    @Test
    public void testCircularIso8601() throws Exception {
        Timestamp t1 = new Timestamp();
        Timestamp t2 = new Timestamp(t1.toIso8601());
        assertEquals(t1.getTime(), t2.getTime());
    }

    @Test
    public void testToIso8601() throws Exception {
        Timestamp t = new Timestamp("2014-09-23T00:00:00-0800");
        assertEquals("2014-09-23T08:00:00.000Z", t.toIso8601());
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

        t = new Timestamp(new Timestamp());
        assertEquals(DateTimeZone.UTC, t.getTime().getZone());

        long ms = DateTime.now(DateTimeZone.forID("EST")).getMillis();
        t = new Timestamp(ms);
        assertEquals(DateTimeZone.UTC, t.getTime().getZone());
    }

}