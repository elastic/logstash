package com.logstash;

import org.junit.Test;
import java.util.*;
import static org.junit.Assert.*;
import static net.javacrumbs.jsonunit.JsonAssert.assertJsonEquals;

public class EventTest {
    @Test
    public void testBareToJson() throws Exception {
        Event e = new Event();
        assertJsonEquals("{\"@timestamp\":\"" + e.getTimestamp().toIso8601() + "\",\"@version\":\"1\"}", e.toJson());
    }

    @Test
    public void testSimpleStringFieldToJson() throws Exception {
        Map data = new HashMap();
        data.put("foo", "bar");
        Event e = new Event(data);
        assertJsonEquals("{\"@timestamp\":\"" + e.getTimestamp().toIso8601() + "\",\"foo\":\"bar\",\"@version\":\"1\"}", e.toJson());
    }

    @Test
    public void testSimpleIntegerFieldToJson() throws Exception {
        Map data = new HashMap();
        data.put("foo", 1);
        Event e = new Event(data);
        assertJsonEquals("{\"@timestamp\":\"" + e.getTimestamp().toIso8601() + "\",\"foo\":1,\"@version\":\"1\"}", e.toJson());
    }

    @Test
    public void testSimpleDecimalFieldToJson() throws Exception {
        Map data = new HashMap();
        data.put("foo", 1.0);
        Event e = new Event(data);
        assertJsonEquals("{\"@timestamp\":\"" + e.getTimestamp().toIso8601() + "\",\"foo\":1.0,\"@version\":\"1\"}", e.toJson());
    }

    @Test
    public void testSimpleMultipleFieldToJson() throws Exception {
        Map data = new HashMap();
        data.put("foo", 1.0);
        data.put("bar", "bar");
        data.put("baz", 1);
        Event e = new Event(data);
        assertJsonEquals("{\"bar\":\"bar\",\"@timestamp\":\"" + e.getTimestamp().toIso8601() + "\",\"foo\":1.0,\"@version\":\"1\",\"baz\":1}", e.toJson());
    }

    @Test
    public void testDeepMapFieldToJson() throws Exception {
        Event e = new Event();
        e.setField("[foo][bar][baz]", 1);
        assertJsonEquals("{\"@timestamp\":\"" + e.getTimestamp().toIso8601() + "\",\"foo\":{\"bar\":{\"baz\":1}},\"@version\":\"1\"}", e.toJson());

        e = new Event();
        e.setField("[foo][0][baz]", 1);
        assertJsonEquals("{\"@timestamp\":\"" + e.getTimestamp().toIso8601() + "\",\"foo\":{\"0\":{\"baz\":1}},\"@version\":\"1\"}", e.toJson());
    }

    @Test
    public void testGetFieldList() throws Exception {
        Map data = new HashMap();
        List l = new ArrayList();
        data.put("foo", l);
        l.add(1);
        Event e = new Event(data);
        assertEquals(1, e.getField("[foo][0]"));
    }

    @Test
    public void testDeepGetField() throws Exception {
        Map data = new HashMap();
        List l = new ArrayList();
        data.put("foo", l);
        Map m = new HashMap();
        m.put("bar", "baz");
        l.add(m);
        Event e = new Event(data);
        assertEquals("baz", e.getField("[foo][0][bar]"));
    }


    @Test
    public void testClone() throws Exception {
        Map data = new HashMap();
        List l = new ArrayList();
        data.put("array", l);

        Map m = new HashMap();
        m.put("foo", "bar");
        l.add(m);

        data.put("foo", 1.0);
        data.put("bar", "bar");
        data.put("baz", 1);

        Event e = new Event(data);

        Event f = e.clone();

        assertJsonEquals("{\"bar\":\"bar\",\"@timestamp\":\"" + e.getTimestamp().toIso8601() + "\",\"array\":[{\"foo\":\"bar\"}],\"foo\":1.0,\"@version\":\"1\",\"baz\":1}", f.toJson());
        assertJsonEquals(f.toJson(), e.toJson());
    }

    @Test
    public void testAppend() throws Exception {
        Map data1 = new HashMap();
        data1.put("field1", Arrays.asList("original1", "original2"));

        Map data2 = new HashMap();
        data2.put("field1", "original1");

        Event e = new Event(data1);
        Event e2 = new Event(data2);
        e.append(e2);

        assertEquals(Arrays.asList("original1", "original2"), e.getField("field1"));
    }
}