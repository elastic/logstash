package org.logstash;

import org.junit.Test;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

public final class FieldReferenceTest {

    @Test
    public void testParseSingleBareField() throws Exception {
        FieldReference f = FieldReference.from("foo");
        assertEquals(0, f.getPath().length);
        assertEquals(f.getKey(), "foo");
    }

    @Test
    public void testParseSingleFieldPath() throws Exception {
        FieldReference f = FieldReference.from("[foo]");
        assertEquals(0, f.getPath().length);
        assertEquals(f.getKey(), "foo");
    }

    @Test
    public void testParse2FieldsPath() throws Exception {
        FieldReference f = FieldReference.from("[foo][bar]");
        assertArrayEquals(f.getPath(), new String[]{"foo"});
        assertEquals(f.getKey(), "bar");
    }

    @Test
    public void testParse3FieldsPath() throws Exception {
        FieldReference f = FieldReference.from("[foo][bar]]baz]");
        assertArrayEquals(f.getPath(), new String[]{"foo", "bar"});
        assertEquals(f.getKey(), "baz");
    }

    @Test
    public void deduplicatesTimestamp() throws Exception {
        assertTrue(FieldReference.from("@timestamp") == FieldReference.from("[@timestamp]"));
    }

    @Test
    public void testParseEmptyString(){
        assertEquals(FieldReference.from(""), FieldReference.DATA_EMPTY_STRING_REFERENCE);
    }

    @Test
    public void testParseNull(){
        assertEquals(FieldReference.from(null), FieldReference.DATA_EMPTY_STRING_REFERENCE);
    }
}
