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

import org.junit.Test;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;

import static org.junit.Assert.assertEquals;

public class KeyNodeTest {

    @Test
    public void testNoElementJoin() throws IOException {
        assertEquals("", KeyNode.join(new ArrayList<>(), ","));
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
