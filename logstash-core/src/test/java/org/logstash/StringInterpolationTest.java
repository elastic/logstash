package org.logstash;


import org.joda.time.DateTime;
import org.joda.time.DateTimeZone;
import org.junit.Test;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import static org.junit.Assert.*;


public class StringInterpolationTest {
    @Test
    public void testCompletelyStaticTemplate() throws IOException {
        Event event = getTestEvent();
        String path = "/full/path/awesome";
        assertEquals(path, StringInterpolation.evaluate(event, path));
    }

    @Test
    public void testOneLevelField() throws IOException {
        Event event = getTestEvent();
        String path = "/full/%{bar}/awesome";
        assertEquals("/full/foo/awesome", StringInterpolation.evaluate(event, path));
    }

    @Test
    public void testMultipleLevelField() throws IOException {
        Event event = getTestEvent();
        String path = "/full/%{bar}/%{awesome}";
        assertEquals("/full/foo/logstash", StringInterpolation.evaluate(event, path));
    }

    @Test
    public void testMissingKey() throws IOException {
        Event event = getTestEvent();
        String path = "/full/%{do-not-exist}";
        assertEquals("/full/%{do-not-exist}", StringInterpolation.evaluate(event, path));
    }

    @Test
    public void testDateFormatter() throws IOException {
        Event event = getTestEvent();
        String path = "/full/%{+YYYY}";
        assertEquals("/full/2015", StringInterpolation.evaluate(event, path));
    }

    @Test
    public void TestMixDateAndFields() throws IOException {
        Event event = getTestEvent();
        String path = "/full/%{+YYYY}/weeee/%{bar}";
        assertEquals("/full/2015/weeee/foo", StringInterpolation.evaluate(event, path));
    }

    @Test
    public void testUnclosedTag() throws IOException {
        Event event = getTestEvent();
        String path = "/full/%{+YYY/web";
        assertEquals("/full/%{+YYY/web", StringInterpolation.evaluate(event, path));
    }

    @Test
    public void TestStringIsOneDateTag() throws IOException {
        Event event = getTestEvent();
        String path = "%{+YYYY}";
        assertEquals("2015", StringInterpolation.evaluate(event, path));
    }

    @Test
    public void TestFieldRef() throws IOException {
        Event event = getTestEvent();
        String path = "%{[j][k1]}";
        assertEquals("v", StringInterpolation.evaluate(event, path));
    }

    @Test
    public void TestEpoch() throws IOException {
        Event event = getTestEvent();
        String path = "%{+%s}";
        assertEquals("1443657600", StringInterpolation.evaluate(event, path));
    }

    @Test
    public void TestValueIsArray() throws IOException {
        ArrayList l = new ArrayList();
        l.add("Hello");
        l.add("world");

        Event event = getTestEvent();
        event.setField("message", l);

        String path = "%{message}";
        assertEquals("Hello,world", StringInterpolation.evaluate(event, path));
    }

    @Test
    public void TestValueIsHash() throws IOException {
        Event event = getTestEvent();

        String path = "%{j}";
        assertEquals("{\"k1\":\"v\"}", StringInterpolation.evaluate(event, path));
    }

    public Event getTestEvent() {
        Map data = new HashMap();
        Map inner = new HashMap();

        inner.put("k1", "v");

        data.put("bar", "foo");
        data.put("awesome", "logstash");
        data.put("j", inner);
        data.put("@timestamp", new DateTime(2015, 10, 1, 0, 0, 0, DateTimeZone.UTC));


        Event event = new Event(data);

        return event;
    }
}
