package org.logstash;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.junit.Rule;
import org.junit.Test;
import org.junit.experimental.theories.DataPoint;
import org.junit.experimental.theories.Theories;
import org.junit.experimental.theories.Theory;
import org.junit.rules.ExpectedException;
import org.junit.runner.RunWith;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

public class AccessorsTest {

    public class TestableAccessors extends Accessors {

        public TestableAccessors(Map<String, Object> data) {
            super(data);
        }

        public Object lutGet(String reference) {
            return this.lut.get(reference);
        }
    }

    @Test
    public void testBareGet() throws Exception {
        Map<String, Object> data = new HashMap<>();
        data.put("foo", "bar");
        String reference = "foo";

        TestableAccessors accessors = new TestableAccessors(data);
        assertNull(accessors.lutGet(reference));
        assertEquals("bar", accessors.get(reference));
        assertEquals(data, accessors.lutGet(reference));
    }

    @Test
    public void testAbsentBareGet() throws Exception {
        Map<String, Object> data = new HashMap<>();
        data.put("foo", "bar");
        String reference = "baz";

        TestableAccessors accessors = new TestableAccessors(data);
        assertNull(accessors.lutGet(reference));
        assertNull(accessors.get(reference));
        assertEquals(data, accessors.lutGet(reference));
    }

    @Test
    public void testBareBracketsGet() throws Exception {
        Map<String, Object> data = new HashMap<>();
        data.put("foo", "bar");
        String reference = "[foo]";

        TestableAccessors accessors = new TestableAccessors(data);
        assertNull(accessors.lutGet(reference));
        assertEquals("bar", accessors.get(reference));
        assertEquals(data, accessors.lutGet(reference));
    }

    @Test
    public void testDeepMapGet() throws Exception {
        Map<String, Object> data = new HashMap<>();
        Map<String, Object> inner = new HashMap<>();
        data.put("foo", inner);
        inner.put("bar", "baz");

        String reference = "[foo][bar]";

        TestableAccessors accessors = new TestableAccessors(data);
        assertNull(accessors.lutGet(reference));
        assertEquals("baz", accessors.get(reference));
        assertEquals(inner, accessors.lutGet(reference));
    }

    @Test
    public void testAbsentDeepMapGet() throws Exception {
        Map<String, Object> data = new HashMap<>();
        Map<String, Object> inner = new HashMap<>();
        data.put("foo", inner);
        inner.put("bar", "baz");

        String reference = "[foo][foo]";

        TestableAccessors accessors = new TestableAccessors(data);
        assertNull(accessors.lutGet(reference));
        assertNull(accessors.get(reference));
        assertEquals(inner, accessors.lutGet(reference));
    }

    @Test
    public void testDeepListGet() throws Exception {
        Map<String, Object> data = new HashMap<>();
        List inner = new ArrayList();
        data.put("foo", inner);
        inner.add("bar");

        String reference = "[foo][0]";

        TestableAccessors accessors = new TestableAccessors(data);
        assertNull(accessors.lutGet(reference));
        assertEquals("bar", accessors.get(reference));
        assertEquals(inner, accessors.lutGet(reference));
    }

    @Test
    public void testAbsentDeepListGet() throws Exception {
        Map<String, Object> data = new HashMap<>();
        List inner = new ArrayList();
        data.put("foo", inner);
        inner.add("bar");

        String reference = "[foo][1]";

        TestableAccessors accessors = new TestableAccessors(data);
        assertNull(accessors.lutGet(reference));
        assertNull(accessors.get(reference));
        assertEquals(inner, accessors.lutGet(reference));
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

        TestableAccessors accessors = new TestableAccessors(data);
        assertNull(accessors.lutGet(reference));
        assertNull(accessors.get(reference));
        assertNull(accessors.set(reference, "obj3"));
        assertEquals(inner, accessors.lutGet(reference));
        assertFalse(accessors.includes(reference));
        assertNull(accessors.del(reference));
    }

    @Test
    public void testBarePut() throws Exception {
        Map<String, Object> data = new HashMap<>();
        String reference = "foo";

        TestableAccessors accessors = new TestableAccessors(data);
        assertNull(accessors.lutGet(reference));
        assertEquals("bar", accessors.set(reference, "bar"));
        assertEquals(data, accessors.lutGet(reference));
        assertEquals("bar", accessors.get(reference));
    }

    @Test
    public void testBareBracketsPut() throws Exception {
        Map<String, Object> data = new HashMap<>();
        String reference = "[foo]";

        TestableAccessors accessors = new TestableAccessors(data);
        assertNull(accessors.lutGet(reference));
        assertEquals("bar", accessors.set(reference, "bar"));
        assertEquals(data, accessors.lutGet(reference));
        assertEquals("bar", accessors.get(reference));
    }

    @Test
    public void testDeepMapSet() throws Exception {
        Map<String, Object> data = new HashMap<>();

        String reference = "[foo][bar]";

        TestableAccessors accessors = new TestableAccessors(data);
        assertNull(accessors.lutGet(reference));
        assertEquals("baz", accessors.set(reference, "baz"));
        assertEquals(accessors.lutGet(reference), data.get("foo"));
        assertEquals("baz", accessors.get(reference));
    }

    @Test
    public void testDel() throws Exception {
        Map<String, Object> data = new HashMap<>();
        List inner = new ArrayList();
        data.put("foo", inner);
        inner.add("bar");
        data.put("bar", "baz");
        TestableAccessors accessors = new TestableAccessors(data);

        assertEquals("bar", accessors.del("[foo][0]"));
        assertNull(accessors.del("[foo][0]"));
        assertEquals(new ArrayList<>(), accessors.get("[foo]"));
        assertEquals("baz", accessors.del("[bar]"));
        assertNull(accessors.get("[bar]"));
    }

    @Test
    public void testNilInclude() throws Exception {
        Map<String, Object> data = new HashMap<>();
        data.put("nilfield", null);
        TestableAccessors accessors = new TestableAccessors(data);
        assertTrue(accessors.includes("nilfield"));
    }

    @Test
    public void testInvalidPath() throws Exception {
        Map<String, Object> data = new HashMap<>();
        Accessors accessors = new Accessors(data);

        assertEquals(1, accessors.set("[foo]", 1));
        assertNull(accessors.get("[foo][bar]"));
    }

    @Test
    public void testStaleTargetCache() throws Exception {
        Map<String, Object> data = new HashMap<>();

        Accessors accessors = new Accessors(data);
        assertNull(accessors.get("[foo][bar]"));
        assertEquals("baz", accessors.set("[foo][bar]", "baz"));
        assertEquals("baz", accessors.get("[foo][bar]"));

        assertEquals("boom", accessors.set("[foo]", "boom"));
        assertNull(accessors.get("[foo][bar]"));
        assertEquals("boom", accessors.get("[foo]"));
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

    @RunWith(Theories.class)
    public static class TestListIndexFailureCases {
      private static final int size = 10;

      @DataPoint
      public static final int tooLarge = size;

      @DataPoint
      public static final int tooLarge1 = size+1;

      @DataPoint
      public static final int tooLargeNegative = -size - 1;

      @Rule
      public ExpectedException exception = ExpectedException.none();

      @Theory
      public void testListIndexOutOfBounds(int i) {
        exception.expect(IndexOutOfBoundsException.class);
        Accessors.listIndex(i, size);
      }
    }

}
