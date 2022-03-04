/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.junit.Test;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

public class AccessorsTest extends RubyTestBase {

    @Test
    public void testBareGet() throws Exception {
        Map<Serializable, Object> data = new HashMap<>();
        data.put("foo", "bar");
        String reference = "foo";
        assertEquals(
            RubyUtil.RUBY.newString("bar"), get(ConvertedMap.newFromMap(data), reference)
        );
    }

    @Test
    public void testAbsentBareGet() throws Exception {
        Map<Serializable, Object>  data = new HashMap<>();
        data.put("foo", "bar");
        String reference = "baz";
        assertNull(get(ConvertedMap.newFromMap(data), reference));
    }

    @Test
    public void testBareBracketsGet() throws Exception {
        Map<Serializable, Object>  data = new HashMap<>();
        data.put("foo", "bar");
        String reference = "[foo]";
        assertEquals(
            RubyUtil.RUBY.newString("bar"), get(ConvertedMap.newFromMap(data), reference)
        );
    }

    @Test
    public void testDeepMapGet() throws Exception {
        Map<Serializable, Object>  data = new HashMap<>();
        Map<Serializable, Object>  inner = new HashMap<>();
        data.put("foo", inner);
        inner.put("bar", "baz");
        String reference = "[foo][bar]";
        assertEquals(
            RubyUtil.RUBY.newString("baz"), get(ConvertedMap.newFromMap(data), reference)
        );
    }

    @Test
    public void testAbsentDeepMapGet() throws Exception {
        Map<Serializable, Object>  data = new HashMap<>();
        Map<Serializable, Object>  inner = new HashMap<>();
        data.put("foo", inner);
        inner.put("bar", "baz");
        String reference = "[foo][foo]";
        assertNull(get(ConvertedMap.newFromMap(data), reference));
    }

    @Test
    public void testDeepListGet() throws Exception {
        Map<Serializable, Object>  data = new HashMap<>();
        List<String> inner = new ArrayList<>();
        data.put("foo", inner);
        inner.add("bar");
        String reference = "[foo][0]";
        assertEquals(
            RubyUtil.RUBY.newString("bar"), get(ConvertedMap.newFromMap(data), reference)
        );
    }

    @Test
    public void testAbsentDeepListGet() throws Exception {
        Map<Serializable, Object>  data = new HashMap<>();
        List<String> inner = new ArrayList<>();
        data.put("foo", inner);
        inner.add("bar");
        String reference = "[foo][1]";
        assertNull(get(ConvertedMap.newFromMap(data), reference));
    }
    /*
     * Check if accessors are able to recovery from
     * failure to convert the key (string) to integer,
     * when it is a non-numeric value, which is not
     * expected.
     */
    @Test
    public void testInvalidIdList() throws Exception {
        final ConvertedMap data = new ConvertedMap(1);
        List<Object> inner = new ConvertedList(2);
        data.put("map1", inner);
        inner.add("obj1");
        inner.add("obj2");

        String reference = "[map1][IdNonNumeric]";

        assertNull(get(data, reference));
        assertNull(set(data, reference, "obj3"));
        assertFalse(includes(data, reference));
        assertNull(del(data, reference));
    }

    @Test
    public void testBarePut() throws Exception {
        final ConvertedMap data = new ConvertedMap(1);
        String reference = "foo";
        assertEquals("bar", set(data, reference, "bar"));
        assertEquals("bar", get(data, reference));
    }

    @Test
    public void testBareBracketsPut() throws Exception {
        final ConvertedMap data = new ConvertedMap(1);
        String reference = "[foo]";

        assertEquals("bar", set(data, reference, "bar"));
        assertEquals("bar", get(data, reference));
    }

    @Test
    public void testDeepMapSet() throws Exception {
        final ConvertedMap data = new ConvertedMap(1);

        String reference = "[foo][bar]";

        assertEquals("baz", set(data, reference, "baz"));
        assertEquals("baz", get(data, reference));
    }

    @Test
    public void testDel() throws Exception {
        final ConvertedMap data = new ConvertedMap(1);
        List<Object> inner = new ConvertedList(1);
        data.put("foo", inner);
        inner.add("bar");
        data.put("bar", "baz");

        assertEquals("bar", del(data, "[foo][0]"));
        assertNull(del(data, "[foo][0]"));
        assertEquals(new ConvertedList(0), get(data,"[foo]"));
        assertEquals("baz", del(data, "[bar]"));
        assertNull(get(data, "[bar]"));
    }

    @Test
    public void testNilInclude() throws Exception {
        final ConvertedMap data = new ConvertedMap(1);
        data.put("nilfield", null);
        assertTrue(includes(data, "nilfield"));
    }

    @Test
    public void testInvalidPath() throws Exception {
        final ConvertedMap data = new ConvertedMap(1);

        assertEquals(1, set(data, "[foo]", 1));
        assertNull(get(data, "[foo][bar]"));
    }

    @Test
    public void testStaleTargetCache() throws Exception {
        final ConvertedMap data = new ConvertedMap(1);

        assertNull(get(data,"[foo][bar]"));
        assertEquals("baz", set(data,"[foo][bar]", "baz"));
        assertEquals("baz", get(data, "[foo][bar]"));

        assertEquals("boom", set(data, "[foo]", "boom"));
        assertNull(get(data, "[foo][bar]"));
        assertEquals("boom", get(data,"[foo]"));
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

    @Test(expected = Accessors.InvalidFieldSetException.class)
    public void testSetOnNonMapOrList() {
        final ConvertedMap data = new ConvertedMap(1);
        set(data, "[foo]", "AString");
        set(data, "[foo][bar]", "Another String");
    }

    private static Object get(final ConvertedMap data, final String reference) {
        return Accessors.get(data, FieldReference.from(reference));
    }

    private static Object set(final ConvertedMap data, final String reference,
        final Object value) {
        return Accessors.set(data, FieldReference.from(reference), value);
    }

    private static Object del(final ConvertedMap data, final String reference) {
        return Accessors.del(data, FieldReference.from(reference));
    }

    private static boolean includes(final ConvertedMap data, final String reference) {
        return Accessors.includes(data, FieldReference.from(reference));
    }
}
