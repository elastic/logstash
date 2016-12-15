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
        StringInterpolation si = StringInterpolation.getInstance();

        assertEquals(path, si.evaluate(event, path));
    }

    @Test
    public void testOneLevelField() throws IOException {
        Event event = getTestEvent();
        String path = "/full/%{bar}/awesome";
        StringInterpolation si = StringInterpolation.getInstance();

        assertEquals("/full/foo/awesome", si.evaluate(event, path));
    }

    @Test
    public void testMultipleLevelField() throws IOException {
        Event event = getTestEvent();
        String path = "/full/%{bar}/%{awesome}";
        StringInterpolation si = StringInterpolation.getInstance();

        assertEquals("/full/foo/logstash", si.evaluate(event, path));
    }

    @Test
    public void testMissingKey() throws IOException {
        Event event = getTestEvent();
        String path = "/full/%{do-not-exist}";
        StringInterpolation si = StringInterpolation.getInstance();

        assertEquals("/full/%{do-not-exist}", si.evaluate(event, path));
    }

    @Test
    public void testDateFormater() throws IOException {
        Event event = getTestEvent();
        String path = "/full/%{+YYYY}";
        StringInterpolation si = StringInterpolation.getInstance();

        assertEquals("/full/2015", si.evaluate(event, path));
    }

    @Test
    public void TestMixDateAndFields() throws IOException {
        Event event = getTestEvent();
        String path = "/full/%{+YYYY}/weeee/%{bar}";
        StringInterpolation si = StringInterpolation.getInstance();

        assertEquals("/full/2015/weeee/foo", si.evaluate(event, path));
    }

    @Test
    public void testUnclosedTag() throws IOException {
        Event event = getTestEvent();
        String path = "/full/%{+YYY/web";
        StringInterpolation si = StringInterpolation.getInstance();

        assertEquals("/full/%{+YYY/web", si.evaluate(event, path));
    }

    @Test
    public void TestStringIsOneDateTag() throws IOException {
        Event event = getTestEvent();
        String path = "%{+YYYY}";
        StringInterpolation si = StringInterpolation.getInstance();
        assertEquals("2015", si.evaluate(event, path));
    }

    @Test
    public void TestFieldRef() throws IOException {
        Event event = getTestEvent();
        String path = "%{[j][k1]}";
        StringInterpolation si = StringInterpolation.getInstance();
        assertEquals("v", si.evaluate(event, path));
    }

    @Test
    public void TestEpoch() throws IOException {
        Event event = getTestEvent();
        String path = "%{+%s}";
        StringInterpolation si = StringInterpolation.getInstance();
        assertEquals("1443657600", si.evaluate(event, path));
    }

    @Test
    public void TestValueIsArray() throws IOException {
        ArrayList l = new ArrayList();
        l.add("Hello");
        l.add("world");

        Event event = getTestEvent();
        event.setField("message", l);

        String path = "%{message}";
        StringInterpolation si = StringInterpolation.getInstance();
        assertEquals("Hello,world", si.evaluate(event, path));
    }

    @Test
    public void TestValueIsHash() throws IOException {
        Event event = getTestEvent();

        String path = "%{j}";
        StringInterpolation si = StringInterpolation.getInstance();
        assertEquals("{\"k1\":\"v\"}", si.evaluate(event, path));
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
