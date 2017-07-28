package org.logstash;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.junit.Test;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

public class AccessorsTest {

    @Test
    public void testBareGet() throws Exception {
        Map<String, Object> data = new HashMap<>();
        data.put("foo", "bar");
        String reference = "foo";
        assertEquals("bar", Accessors.get(data, reference));
    }

    @Test
    public void testAbsentBareGet() throws Exception {
        Map<String, Object> data = new HashMap<>();
        data.put("foo", "bar");
        String reference = "baz";
        assertNull(Accessors.get(data, reference));
    }

    @Test
    public void testBareBracketsGet() throws Exception {
        Map<String, Object> data = new HashMap<>();
        data.put("foo", "bar");
        String reference = "[foo]";

        
        assertEquals("bar", Accessors.get(data, reference));
    }

    @Test
    public void testDeepMapGet() throws Exception {
        Map<String, Object> data = new HashMap<>();
        Map<String, Object> inner = new HashMap<>();
        data.put("foo", inner);
        inner.put("bar", "baz");

        String reference = "[foo][bar]";
        assertEquals("baz", Accessors.get(data, reference));
    }

    @Test
    public void testAbsentDeepMapGet() throws Exception {
        Map<String, Object> data = new HashMap<>();
        Map<String, Object> inner = new HashMap<>();
        data.put("foo", inner);
        inner.put("bar", "baz");

        String reference = "[foo][foo]";
        assertNull(Accessors.get(data, reference));
    }

    @Test
    public void testDeepListGet() throws Exception {
        Map<String, Object> data = new HashMap<>();
        List inner = new ArrayList();
        data.put("foo", inner);
        inner.add("bar");

        String reference = "[foo][0]";

        assertEquals("bar", Accessors.get(data, reference));
    }

    @Test
    public void testAbsentDeepListGet() throws Exception {
        Map<String, Object> data = new HashMap<>();
        List inner = new ArrayList();
        data.put("foo", inner);
        inner.add("bar");

        String reference = "[foo][1]";

        assertNull(Accessors.get(data, reference));
    }
    /*
     * Check if accessors are able to recovery from
     * failure to convert the key (string) to integer,
     * when it is a non-numeric value, which is not
     * expected.
     */
    @Test
    public void testInvalidIdList() throws Exception {
        Map<String, Object> data = new HashMap<>();
        List inner = new ArrayList();
        data.put("map1", inner);
        inner.add("obj1");
        inner.add("obj2");

        String reference = "[map1][IdNonNumeric]";

        assertNull(Accessors.get(data, reference));
        assertNull(Accessors.set(data, reference, "obj3"));
        assertFalse(Accessors.includes(data, reference));
        assertNull(Accessors.del(data, reference));
    }

    @Test
    public void testBarePut() throws Exception {
        Map<String, Object> data = new HashMap<>();
        String reference = "foo";
        assertEquals("bar", Accessors.set(data, reference, "bar"));
        assertEquals("bar", Accessors.get(data, reference));
    }

    @Test
    public void testBareBracketsPut() throws Exception {
        Map<String, Object> data = new HashMap<>();
        String reference = "[foo]";

        assertEquals("bar", Accessors.set(data, reference, "bar"));
        assertEquals("bar", Accessors.get(data, reference));
    }

    @Test
    public void testDeepMapSet() throws Exception {
        Map<String, Object> data = new HashMap<>();

        String reference = "[foo][bar]";

        assertEquals("baz", Accessors.set(data, reference, "baz"));
        assertEquals("baz", Accessors.get(data, reference));
    }

    @Test
    public void testDel() throws Exception {
        Map<String, Object> data = new HashMap<>();
        List inner = new ArrayList();
        data.put("foo", inner);
        inner.add("bar");
        data.put("bar", "baz");

        assertEquals("bar", Accessors.del(data, "[foo][0]"));
        assertNull(Accessors.del(data, "[foo][0]"));
        assertEquals(new ArrayList<>(), Accessors.get(data,"[foo]"));
        assertEquals("baz", Accessors.del(data, "[bar]"));
        assertNull(Accessors.get(data, "[bar]"));
    }

    @Test
    public void testNilInclude() throws Exception {
        Map<String, Object> data = new HashMap<>();
        data.put("nilfield", null);
        assertTrue(Accessors.includes(data, "nilfield"));
    }

    @Test
    public void testInvalidPath() throws Exception {
        Map<String, Object> data = new HashMap<>();

        assertEquals(1, Accessors.set(data, "[foo]", 1));
        assertNull(Accessors.get(data, "[foo][bar]"));
    }

    @Test
    public void testStaleTargetCache() throws Exception {
        Map<String, Object> data = new HashMap<>();

        assertNull(Accessors.get(data,"[foo][bar]"));
        assertEquals("baz", Accessors.set(data,"[foo][bar]", "baz"));
        assertEquals("baz", Accessors.get(data, "[foo][bar]"));

        assertEquals("boom", Accessors.set(data, "[foo]", "boom"));
        assertNull(Accessors.get(data, "[foo][bar]"));
        assertEquals("boom", Accessors.get(data,"[foo]"));
    }

    @Test
    public void testListIndexOutOfBounds() {
        assertEquals(0, Accessors.listIndex(0, 10));
        assertEquals(1, Accessors.listIndex(1, 10));
        assertEquals(9, Accessors.listIndex(9, 10));
        assertEquals(9, Accessors.listIndex(-1, 10));
        assertEquals(1, Accessors.listIndex(-9, 10));
        assertEquals(0, Accessors.listIndex(-10, 10));
    }
}
