package com.logstash;

import org.junit.Test;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.BigInteger;
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
    public void testToMap() throws Exception {
        Event e = new Event();
        Map original = e.getData();
        Map clone = e.toMap();
        assertFalse(original == clone);
        assertEquals(original, clone);
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

    @Test
    public void testFromJsonWithNull() throws Exception {
        Event[] events = Event.fromJson(null);
        assertEquals(0, events.length);
    }

    @Test
    public void testFromJsonWithEmptyString() throws Exception {
        Event[] events = Event.fromJson("");
        assertEquals(0, events.length);
    }

    @Test
    public void testFromJsonWithBlankString() throws Exception {
        Event[] events = Event.fromJson("   ");
        assertEquals(0, events.length);
    }

    @Test
    public void testFromJsonWithValidJsonMap() throws Exception {
        Event e = Event.fromJson("{\"@timestamp\":\"2015-05-28T23:02:05.350Z\",\"foo\":\"bar\"}")[0];

        assertEquals("bar", e.getField("[foo]"));
        assertEquals("2015-05-28T23:02:05.350Z", e.getTimestamp().toIso8601());
    }

    @Test
    public void testFromJsonWithValidJsonArrayOfMap() throws Exception {
        Event[] l = Event.fromJson("[{\"@timestamp\":\"2015-05-28T23:02:05.350Z\",\"foo\":\"bar\"}]");

        assertEquals(1, l.length);
        assertEquals("bar", l[0].getField("[foo]"));
        assertEquals("2015-05-28T23:02:05.350Z", l[0].getTimestamp().toIso8601());

        l = Event.fromJson("[{}]");

        assertEquals(1, l.length);
        assertEquals(null, l[0].getField("[foo]"));

        l = Event.fromJson("[{\"@timestamp\":\"2015-05-28T23:02:05.350Z\",\"foo\":\"bar\"}, {\"@timestamp\":\"2016-05-28T23:02:05.350Z\",\"foo\":\"baz\"}]");

        assertEquals(2, l.length);
        assertEquals("bar", l[0].getField("[foo]"));
        assertEquals("2015-05-28T23:02:05.350Z", l[0].getTimestamp().toIso8601());
        assertEquals("baz", l[1].getField("[foo]"));
        assertEquals("2016-05-28T23:02:05.350Z", l[1].getTimestamp().toIso8601());
    }

    @Test(expected=IOException.class)
    public void testFromJsonWithInvalidJsonString() throws Exception {
        Event.fromJson("gabeutch");
    }

    @Test(expected=IOException.class)
    public void testFromJsonWithInvalidJsonArray1() throws Exception {
        Event.fromJson("[1,2]");
    }

    @Test(expected=IOException.class)
    public void testFromJsonWithInvalidJsonArray2() throws Exception {
        Event.fromJson("[\"gabeutch\"]");
    }

    @Test(expected=IOException.class)
    public void testFromJsonWithPartialInvalidJsonArray() throws Exception {
        Event.fromJson("[{\"foo\":\"bar\"}, 1]");
    }

    @Test
    public void testByteSerializeRoundTrip() throws Exception {
        String pangramDe = "Victor jagt zwölf Boxkämpfer quer über den großen Sylter Deich";
        String pangramEn = "Jived fox nymph grabs quick waltz";
        long num = 87654321;
        BigDecimal bd = BigDecimal.valueOf(123456789.99);
        BigInteger bi = BigInteger.valueOf(num);
        Timestamp t = new Timestamp("2014-09-23T08:00:00.000Z");

        Map data = new HashMap();
        data.put("a", 1);
        data.put("b", "bar");
        data.put("c", 1.0);

        Map meta = new HashMap();
        meta.put("g", pangramDe);

        data.put(Event.METADATA, meta);
        Event e = new Event(data);

        e.setField("[d]", num);
        e.setField("[e]", bd);
        e.setField("[f]", bi);
        e.setField("[@metadata][h]", pangramEn);
        e.setField(Event.TIMESTAMP, t);
        e.cancel();

        byte[] oneWay = e.byteSerialize();
        Event returnTrip = Event.byteDeserialize(oneWay);

        assertEquals(272, oneWay.length);
        assertNotEquals(t, returnTrip.getTimestamp());
        assertEquals(t.toIso8601(), returnTrip.getTimestamp().toIso8601());
        assertEquals(1, returnTrip.getField("[a]"));
        assertEquals("bar", returnTrip.getField("[b]"));
        assertEquals(1.0, returnTrip.getField("[c]"));
        assertEquals(num, returnTrip.getField("[d]"));
        assertEquals(bd, returnTrip.getField("[e]"));
        assertEquals(bi, returnTrip.getField("[f]"));
        assertEquals(pangramDe, returnTrip.getField("[@metadata][g]"));
        assertEquals(pangramEn, returnTrip.getField("[@metadata][h]"));
        assertTrue(returnTrip.isCancelled());
    }
}
