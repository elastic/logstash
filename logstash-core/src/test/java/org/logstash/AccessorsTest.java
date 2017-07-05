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

public class AccessorsTest {

    public class TestableAccessors extends Accessors {

        public TestableAccessors(Map data) {
            super(data);
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
    /*
     * Check if accessors are able to recovery from
     * failure to convert the key (string) to integer,
     * when it is a non-numeric value, which is not
     * expected.
     */
    @Test
    public void testInvalidIdList() throws Exception {
        Map data = new HashMap();
        List inner = new ArrayList();
        data.put("map1", inner);
        inner.add("obj1");
        inner.add("obj2");

        String reference = "[map1][IdNonNumeric]";

        TestableAccessors accessors = new TestableAccessors(data);
        assertEquals(accessors.lutGet(reference), null);
        assertEquals(accessors.get(reference), null);
        assertEquals(accessors.set(reference, "obj3"), null);
        assertEquals(accessors.lutGet(reference), inner);
        assertFalse(accessors.includes(reference));
        assertEquals(accessors.del(reference), null);
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

    @Test
    public void testListIndexOutOfBounds() {
        assertEquals(Accessors.listIndex(0, 10), 0);
        assertEquals(Accessors.listIndex(1, 10), 1);
        assertEquals(Accessors.listIndex(9, 10), 9);
        assertEquals(Accessors.listIndex(-1, 10), 9);
        assertEquals(Accessors.listIndex(-9, 10), 1);
        assertEquals(Accessors.listIndex(-10, 10), 0);
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
