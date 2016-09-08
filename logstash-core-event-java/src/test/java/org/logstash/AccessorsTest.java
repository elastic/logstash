package org.logstash;

import org.junit.Test;

import static org.junit.Assert.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class AccessorsTest {

    public class TestableAccessors extends Accessors {

        public TestableAccessors(Map data) {
            super(data);
        }

        public Map<String, Object> getLut() {
            return lut;
        }

        public Object lutGet(String reference) {
            return this.lut.get(reference);
        }
    }

    @Test
    public void testBareGet() throws Exception {
        Map data = new HashMap();
        data.put("foo", "bar");
        String reference = "foo";

        TestableAccessors accessors = new TestableAccessors(data);
        assertEquals(accessors.lutGet(reference), null);
        assertEquals(accessors.get(reference), "bar");
        assertEquals(accessors.lutGet(reference), data);
    }

    @Test
    public void testAbsentBareGet() throws Exception {
        Map data = new HashMap();
        data.put("foo", "bar");
        String reference = "baz";

        TestableAccessors accessors = new TestableAccessors(data);
        assertEquals(accessors.lutGet(reference), null);
        assertEquals(accessors.get(reference), null);
        assertEquals(accessors.lutGet(reference), data);
    }

    @Test
    public void testBareBracketsGet() throws Exception {
        Map data = new HashMap();
        data.put("foo", "bar");
        String reference = "[foo]";

        TestableAccessors accessors = new TestableAccessors(data);
        assertEquals(accessors.lutGet(reference), null);
        assertEquals(accessors.get(reference), "bar");
        assertEquals(accessors.lutGet(reference), data);
    }

    @Test
    public void testDeepMapGet() throws Exception {
        Map data = new HashMap();
        Map inner = new HashMap();
        data.put("foo", inner);
        inner.put("bar", "baz");

        String reference = "[foo][bar]";

        TestableAccessors accessors = new TestableAccessors(data);
        assertEquals(accessors.lutGet(reference), null);
        assertEquals(accessors.get(reference), "baz");
        assertEquals(accessors.lutGet(reference), inner);
    }

    @Test
    public void testAbsentDeepMapGet() throws Exception {
        Map data = new HashMap();
        Map inner = new HashMap();
        data.put("foo", inner);
        inner.put("bar", "baz");

        String reference = "[foo][foo]";

        TestableAccessors accessors = new TestableAccessors(data);
        assertEquals(accessors.lutGet(reference), null);
        assertEquals(accessors.get(reference), null);
        assertEquals(accessors.lutGet(reference), inner);
    }

    @Test
    public void testDeepListGet() throws Exception {
        Map data = new HashMap();
        List inner = new ArrayList();
        data.put("foo", inner);
        inner.add("bar");

        String reference = "[foo][0]";

        TestableAccessors accessors = new TestableAccessors(data);
        assertEquals(accessors.lutGet(reference), null);
        assertEquals(accessors.get(reference), "bar");
        assertEquals(accessors.lutGet(reference), inner);
    }

    @Test
    public void testAbsentDeepListGet() throws Exception {
        Map data = new HashMap();
        List inner = new ArrayList();
        data.put("foo", inner);
        inner.add("bar");

        String reference = "[foo][1]";

        TestableAccessors accessors = new TestableAccessors(data);
        assertEquals(accessors.lutGet(reference), null);
        assertEquals(accessors.get(reference), null);
        assertEquals(accessors.lutGet(reference), inner);
    }

    @Test
    public void testBarePut() throws Exception {
        Map data = new HashMap();
        String reference = "foo";

        TestableAccessors accessors = new TestableAccessors(data);
        assertEquals(accessors.lutGet(reference), null);
        assertEquals(accessors.set(reference, "bar"), "bar");
        assertEquals(accessors.lutGet(reference), data);
        assertEquals(accessors.get(reference), "bar");
    }

    @Test
    public void testBareBracketsPut() throws Exception {
        Map data = new HashMap();
        String reference = "[foo]";

        TestableAccessors accessors = new TestableAccessors(data);
        assertEquals(accessors.lutGet(reference), null);
        assertEquals(accessors.set(reference, "bar"), "bar");
        assertEquals(accessors.lutGet(reference), data);
        assertEquals(accessors.get(reference), "bar");
    }

    @Test
    public void testDeepMapSet() throws Exception {
        Map data = new HashMap();

        String reference = "[foo][bar]";

        TestableAccessors accessors = new TestableAccessors(data);
        assertEquals(accessors.lutGet(reference), null);
        assertEquals(accessors.set(reference, "baz"), "baz");
        assertEquals(accessors.lutGet(reference), data.get("foo"));
        assertEquals(accessors.get(reference), "baz");
    }

    @Test
    public void testDel() throws Exception {
        Map data = new HashMap();
        List inner = new ArrayList();
        data.put("foo", inner);
        inner.add("bar");
        data.put("bar", "baz");
        TestableAccessors accessors = new TestableAccessors(data);

        assertEquals(accessors.del("[foo][0]"), "bar");
        assertEquals(accessors.del("[foo][0]"), null);
        assertEquals(accessors.get("[foo]"), new ArrayList<>());
        assertEquals(accessors.del("[bar]"), "baz");
        assertEquals(accessors.get("[bar]"), null);
    }

    @Test
    public void testNilInclude() throws Exception {
        Map data = new HashMap();
        data.put("nilfield", null);
        TestableAccessors accessors = new TestableAccessors(data);

        assertEquals(accessors.includes("nilfield"), true);
    }

    @Test
    public void testInvalidPath() throws Exception {
        Map data = new HashMap();
        Accessors accessors = new Accessors(data);

        assertEquals(accessors.set("[foo]", 1), 1);
        assertEquals(accessors.get("[foo][bar]"), null);
    }

    @Test
    public void testStaleTargetCache() throws Exception {
        Map data = new HashMap();

        Accessors accessors = new Accessors(data);

        assertEquals(accessors.get("[foo][bar]"), null);
        assertEquals(accessors.set("[foo][bar]", "baz"), "baz");
        assertEquals(accessors.get("[foo][bar]"), "baz");

        assertEquals(accessors.set("[foo]", "boom"), "boom");
        assertEquals(accessors.get("[foo][bar]"), null);
        assertEquals(accessors.get("[foo]"), "boom");
    }
}
