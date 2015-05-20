package com.logstash;

import org.jruby.ir.operands.Hash;
import org.junit.Test;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.Assert.*;

public class EventTest {

    @Test
    public void testBareToJson() throws Exception {
        Event e = new EventImpl();
        assertEquals("{\"@timestamp\":\"" + e.getTimestamp().toIso8601() + "\",\"@version\":\"1\"}", e.toJson());
    }

    @Test
    public void testSimpleStringFieldToJson() throws Exception {
        Map data = new HashMap();
        data.put("foo", "bar");
        Event e = new EventImpl(data);
        assertEquals("{\"@timestamp\":\"" + e.getTimestamp().toIso8601() + "\",\"foo\":\"bar\",\"@version\":\"1\"}", e.toJson());
    }

    @Test
    public void testSimpleIntegerFieldToJson() throws Exception {
        Map data = new HashMap();
        data.put("foo", 1);
        Event e = new EventImpl(data);
        assertEquals("{\"@timestamp\":\"" + e.getTimestamp().toIso8601() + "\",\"foo\":1,\"@version\":\"1\"}", e.toJson());
    }

    @Test
    public void testSimpleDecimalFieldToJson() throws Exception {
        Map data = new HashMap();
        data.put("foo", 1.0);
        Event e = new EventImpl(data);
        assertEquals("{\"@timestamp\":\"" + e.getTimestamp().toIso8601() + "\",\"foo\":1.0,\"@version\":\"1\"}", e.toJson());
    }

    @Test
    public void testSimpleMultipleFieldToJson() throws Exception {
        Map data = new HashMap();
        data.put("foo", 1.0);
        data.put("bar", "bar");
        data.put("baz", 1);
        Event e = new EventImpl(data);
        assertEquals("{\"bar\":\"bar\",\"@timestamp\":\"" + e.getTimestamp().toIso8601() + "\",\"foo\":1.0,\"@version\":\"1\",\"baz\":1}", e.toJson());
    }

    @Test
    public void testDeepMapFieldToJson() throws Exception {
        Event e = new EventImpl();
        e.setField("[foo][bar][baz]", 1);
        assertEquals("{\"@timestamp\":\"" + e.getTimestamp().toIso8601() + "\",\"foo\":{\"bar\":{\"baz\":1}},\"@version\":\"1\"}", e.toJson());

        e = new EventImpl();
        e.setField("[foo][0][baz]", 1);
        assertEquals("{\"@timestamp\":\"" + e.getTimestamp().toIso8601() + "\",\"foo\":{\"0\":{\"baz\":1}},\"@version\":\"1\"}", e.toJson());
    }

    @Test
    public void testGetFieldList() throws Exception {
        Map data = new HashMap();
        List l = new ArrayList();
        data.put("foo", l);
        l.add(1);
        Event e = new EventImpl(data);
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
        Event e = new EventImpl(data);
        assertEquals("baz", e.getField("[foo][0][bar]"));
    }
}