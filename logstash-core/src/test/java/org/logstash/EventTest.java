package org.logstash;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.junit.Test;

import static net.javacrumbs.jsonunit.JsonAssert.assertJsonEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;

public class EventTest {

    @Test
    public void queueableInterfaceRoundTrip() throws Exception {
        Event e = new Event();
        e.setField("foo", 42L);
        e.setField("bar", 42);
        Map<String, Object> inner = new HashMap<>(2);
        inner.put("innerFoo", 42L);
        inner.put("innerQuux", 42.42);
        e.setField("baz", inner);
        e.setField("[@metadata][foo]", 42L);
        byte[] binary = e.serialize();
        Event er = Event.deserialize(binary);
        assertEquals(42L, er.getField("foo"));
        assertEquals(42, er.getField("bar"));
        assertEquals(42L, er.getField("[baz][innerFoo]"));
        assertEquals(42.42, er.getField("[baz][innerQuux]"));
        assertEquals(42L, er.getField("[@metadata][foo]"));

        assertEquals(e.getTimestamp().toIso8601(), er.getTimestamp().toIso8601());
    }

    @Test
    public void toBinaryRoundtrip() throws Exception {
        Event e = new Event();
        e.setField("foo", 42L);
        e.setField("bar", 42);
        Map<String, Object> inner = new HashMap<>(2);
        inner.put("innerFoo", 42L);
        inner.put("innerQuux", 42.42);
        e.setField("baz", inner);
        e.setField("[@metadata][foo]", 42L);
        Event er = Event.deserialize(e.serialize());
        assertEquals(42L, er.getField("foo"));
        assertEquals(42, er.getField("bar"));
        assertEquals(42L, er.getField("[baz][innerFoo]"));
        assertEquals(42.42, er.getField("[baz][innerQuux]"));
        assertEquals(42L, er.getField("[@metadata][foo]"));

        assertEquals(e.getTimestamp().toIso8601(), er.getTimestamp().toIso8601());
    }

    @Test
    public void testBareToJson() throws Exception {
        Event e = new Event();
        assertJsonEquals("{\"@timestamp\":\"" + e.getTimestamp().toIso8601() + "\",\"@version\":\"1\"}", e.toJson());
    }

    @Test
    public void testSimpleStringFieldToJson() throws Exception {
        Map<String, Object> data = new HashMap<>();
        data.put("foo", "bar");
        Event e = new Event(data);
        assertJsonEquals("{\"@timestamp\":\"" + e.getTimestamp().toIso8601() + "\",\"foo\":\"bar\",\"@version\":\"1\"}", e.toJson());
    }

    @Test
    public void testSimpleIntegerFieldToJson() throws Exception {
        Map<String, Object> data = new HashMap<>();
        data.put("foo", 1);
        Event e = new Event(data);
        assertJsonEquals("{\"@timestamp\":\"" + e.getTimestamp().toIso8601() + "\",\"foo\":1,\"@version\":\"1\"}", e.toJson());
    }

    @Test
    public void testSimpleDecimalFieldToJson() throws Exception {
        Map<String, Object> data = new HashMap<>();
        data.put("foo", 1.0);
        Event e = new Event(data);
        assertJsonEquals("{\"@timestamp\":\"" + e.getTimestamp().toIso8601() + "\",\"foo\":1.0,\"@version\":\"1\"}", e.toJson());
    }

    @Test
    public void testSimpleMultipleFieldToJson() throws Exception {
        Map<String, Object> data = new HashMap<>();
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
        Map<String, Object> data = new HashMap<>();
        List<Object> l = new ArrayList<>();
        data.put("foo", l);
        l.add(1);
        Event e = new Event(data);
        assertEquals(1, e.getField("[foo][0]"));
    }

    @Test
    public void testDeepGetField() throws Exception {
        Map<String, Object> data = new HashMap<>();
        List<Object> l = new ArrayList<>();
        data.put("foo", l);
        Map<String, Object> m = new HashMap<>();
        m.put("bar", "baz");
        l.add(m);
        Event e = new Event(data);
        assertEquals("baz", e.getField("[foo][0][bar]"));
    }


    @Test
    public void testClone() throws Exception {
        Map<String, Object> data = new HashMap<>();
        List<Object> l = new ArrayList<>();
        data.put("array", l);

        Map<String, Object> m = new HashMap<>();
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
        Map<String, Object> original = e.getData();
        Map<String, Object> clone = e.toMap();
        assertFalse(original == clone);
        assertEquals(original, clone);
    }

    @Test
    public void testAppend() throws Exception {
        Map<String, Object> data1 = new HashMap<>();
        data1.put("field1", Arrays.asList("original1", "original2"));

        Map<String, Object> data2 = new HashMap<>();
        data2.put("field1", "original1");

        Event e = new Event(data1);
        Event e2 = new Event(data2);
        e.append(e2);

        assertEquals(2, ((List) e.getField("[field1]")).size());
        assertEquals("original1", e.getField("[field1][0]"));
        assertEquals("original2", e.getField("[field1][1]"));
    }

    @Test
    public void testAppendLists() throws Exception {
        Map<String, Object> data1 = new HashMap<>();
        data1.put("field1", Arrays.asList("original1", "original2"));

        Map<String, Object> data2 = new HashMap<>();
        data2.put("field1", Arrays.asList("original3", "original4"));

        Event e = new Event(data1);
        Event e2 = new Event(data2);
        e.append(e2);

        assertEquals(4, ((List) e.getField("[field1]")).size());
        assertEquals("original1", e.getField("[field1][0]"));
        assertEquals("original2", e.getField("[field1][1]"));
        assertEquals("original3", e.getField("[field1][2]"));
        assertEquals("original4", e.getField("[field1][3]"));
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
    public void testTagOnEmptyTagsField() throws Exception {
        Event e = new Event();
        e.tag("foo");

        List<String> tags = (List<String>)e.getField("tags");
        assertEquals(tags.size(), 1);
        assertEquals(tags.get(0), "foo");
    }

    @Test
    public void testTagOnExistingTagsField() throws Exception {
        Map<String, Object> data = new HashMap<>();
        data.put("tags", "foo");
        Event e = new Event(data);
        e.tag("bar");

        List<String> tags = (List<String>)e.getField("tags");
        assertEquals(tags.size(), 2);
        assertEquals(tags.get(0), "foo");
        assertEquals(tags.get(1), "bar");
    }

    @Test
    public void toStringwithTimestamp() throws Exception {
        Map<String, Object> data = new HashMap<>();
        data.put("host", "foo");
        data.put("message", "bar");
        Event e = new Event(data);
        assertEquals(e.toString(), e.getTimestamp().toIso8601() + " foo bar");
    }

    @Test
    public void toStringwithoutTimestamp() throws Exception {
        Map<String, Object> data = new HashMap<>();
        data.put("host", "foo");
        data.put("message", "bar");
        Event e = new Event(data);
        e.remove("@timestamp");
        assertEquals(e.toString(), "foo bar");

        e = new Event();
        e.remove("@timestamp");
        assertEquals(e.toString(), "%{host} %{message}");
    }
}
