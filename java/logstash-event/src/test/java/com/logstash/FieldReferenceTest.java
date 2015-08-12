package com.logstash;

import org.junit.Test;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static org.junit.Assert.*;

public class FieldReferenceTest {

    @Test
    public void testParseSingleBareField() throws Exception {
        FieldReference f = FieldReference.parse("foo");
        assertTrue(f.getPath().isEmpty());
        assertEquals(f.getKey(), "foo");
    }

    @Test
    public void testParseSingleFieldPath() throws Exception {
        FieldReference f = FieldReference.parse("[foo]");
        assertTrue(f.getPath().isEmpty());
        assertEquals(f.getKey(), "foo");
    }

    @Test
    public void testParse2FieldsPath() throws Exception {
        FieldReference f = FieldReference.parse("[foo][bar]");
        assertEquals(f.getPath().toArray(), new String[]{"foo"});
        assertEquals(f.getKey(), "bar");
    }

    @Test
    public void testParse3FieldsPath() throws Exception {
        FieldReference f = FieldReference.parse("[foo][bar]]baz]");
        assertEquals(f.getPath().toArray(), new String[]{"foo", "bar"});
        assertEquals(f.getKey(), "baz");
    }
}