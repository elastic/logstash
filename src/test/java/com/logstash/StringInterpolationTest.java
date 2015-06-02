package com.logstash;


import org.junit.Test;

import java.util.HashMap;
import java.util.Map;

import static org.junit.Assert.*;


public class StringInterpolationTest {
    @Test
    public void testCompletelyStaticTemplate() {
        Event event = getTestEvent();
        String path = "/full/path/awesome";
        StringInterpolation si = StringInterpolation.getInstance();

        assertEquals(path, si.evaluate(event, path));
    }

    @Test
    public void testOneLevelField() {
        Event event = getTestEvent();
        String path = "/full/%{bar}/awesome";
        StringInterpolation si = StringInterpolation.getInstance();

        assertEquals("/full/foo/awesome", si.evaluate(event, path));
    }

    @Test
    public void testMultipleLevelField() {
        Event event = getTestEvent();
        String path = "/full/%{bar}/%{awesome}";
        StringInterpolation si = StringInterpolation.getInstance();

        assertEquals("/full/foo/logstash", si.evaluate(event, path));
    }

    @Test
    public void testMissingKey() {
        Event event = getTestEvent();
        String path = "/full/%{do-not-exist}";
        StringInterpolation si = StringInterpolation.getInstance();

        assertEquals("/full/%{do-not-exist}", si.evaluate(event, path));
    }

    @Test
    public void testDateFormater() {
        Event event = getTestEvent();
        String path = "/full/%{+YYYY}";
        StringInterpolation si = StringInterpolation.getInstance();

        assertEquals("/full/2015", si.evaluate(event, path));
    }

    @Test
    public void TestMixDateAndFields() {
        Event event = getTestEvent();
        String path = "/full/%{+YYYY}/weeee/%{bar}";
        StringInterpolation si = StringInterpolation.getInstance();

        assertEquals("/full/2015/weeee/foo", si.evaluate(event, path));
    }

    @Test
    public void testUnclosedTag() {
        Event event = getTestEvent();
        String path = "/full/%{+YYY/web";
        StringInterpolation si = StringInterpolation.getInstance();

        assertEquals("/full/%{+YYY/web", si.evaluate(event, path));
    }

    public Event getTestEvent() {
        Map data = new HashMap();
        data.put("bar", "foo");
        data.put("awesome", "logstash");
        Event event = new EventImpl(data);

        return event;
    }
}
