package org.logstash;

import org.junit.Test;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;

import static org.junit.Assert.assertEquals;

public class KeyNodeTest {

    @Test
    public void testNoElementJoin() throws IOException {
        assertEquals("", KeyNode.join(new ArrayList(), ","));
    }

    @Test
    public void testOneElementJoin() throws IOException {
        assertEquals("foo", KeyNode.join(Arrays.asList("foo"), ","));
    }

    @Test
    public void testOneNullElementJoin() throws IOException {
        assertEquals("", KeyNode.join(Arrays.asList(new Object[] { null }), ","));
    }

    @Test
    public void testTwoElementJoin() throws IOException {
        assertEquals("foo,bar", KeyNode.join(Arrays.asList("foo", "bar"), ","));
    }

    @Test
    public void testTwoElementWithLeadingNullJoin() throws IOException {
        assertEquals(",foo", KeyNode.join(Arrays.asList(null, "foo"), ","));
    }

    @Test
    public void testTwoElementWithTailingNullJoin() throws IOException {
        assertEquals("foo,", KeyNode.join(Arrays.asList("foo", null), ","));
    }

    @Test
    public void testListInListJoin() throws IOException {
        assertEquals("foo,bar,", KeyNode.join(Arrays.asList("foo", Arrays.asList("bar", null)), ","));
    }
}
