package com.logstash;

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
    public void testTwoElementJoin() throws IOException {
        assertEquals("foo,bar", KeyNode.join(Arrays.asList("foo", "bar"), ","));
    }
}
