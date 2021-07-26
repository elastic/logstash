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

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.number.OrderingComparison.greaterThan;
import static org.hamcrest.number.OrderingComparison.lessThan;
import static org.hamcrest.number.OrderingComparison.lessThanOrEqualTo;
import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertSame;

public final class FieldReferenceTest {

    @Before
    @After
    public void clearParsingCache() {
        FieldReference.CACHE.cleanUp();
        FieldReference.RUBY_CACHE.cleanUp();
    }

    @Test
    public void deduplicatesTimestamp() {
        assertSame(FieldReference.TIMESTAMP_REFERENCE, FieldReference.from("@timestamp"));
        assertSame(FieldReference.from("@timestamp"), FieldReference.from("[@timestamp]"));
    }

    @Test
    public void testParseEmptyString() {
        final FieldReference emptyReference = FieldReference.from("");
        assertNotNull(emptyReference);
        assertEquals(
                emptyReference, FieldReference.from(RubyUtil.RUBY.newString(""))
        );
    }

    @Test
    public void testCacheUpperBound() {
        final int initial = (int) FieldReference.CACHE.size();
        for (int i = 0; i < FieldReference.CACHE_MAXIMUM_SIZE - initial + 10; ++i) {
            assertNotNull( FieldReference.from(String.format("[array][%d]", i)) );
        }
        final int cacheSize = (int) FieldReference.CACHE.size();
        assertThat(cacheSize, lessThanOrEqualTo(FieldReference.CACHE_MAXIMUM_SIZE));
        assertThat(cacheSize, greaterThan(FieldReference.CACHE_MAXIMUM_SIZE / 2));
    }

    @Test
    public void testRubyCacheUpperBound() {
        for (int i = 0; i < FieldReference.CACHE_MAXIMUM_SIZE + 100; ++i) {
            FieldReference.from(RubyUtil.RUBY.newString(String.format("[some_stuff][%d]", i)));
        }
        final int cacheSize = (int) FieldReference.RUBY_CACHE.size();
        assertThat(cacheSize, lessThanOrEqualTo(FieldReference.CACHE_MAXIMUM_SIZE));
        assertThat(cacheSize, greaterThan(FieldReference.CACHE_MAXIMUM_SIZE / 2));
    }

//    @Test
//    public void testDeduplicationWithWeakRefs() {
//        for (int i = 0; i < FieldReference.CACHE_MAXIMUM_SIZE; ++i) {
//            assertNotNull( FieldReference.from(String.format("[dedup][%d]", i)) );
//        }
//
//        // NOTE: weak refs are hard to test - we just loosely assert map is not growing "too much"
//
//        // deduplication logic should not grow map indefinitely :
//        System.gc();
//        for (int i = 0; i < 10_000; ++i) {
//            assertNotNull( FieldReference.from(String.format("[dedup1][%d]", i)) );
//        }
//        System.gc();
//        for (int i = 0; i < 100_000; ++i) {
//            assertNotNull( FieldReference.from(String.format("[dedup2][%d]", i)) );
//        }
//        System.gc(); System.gc();
//        for (int i = 0; i < 1_000_000; ++i) { // TODO: depends on the heap size / gc used
//            assertNotNull( FieldReference.from(String.format("[dedup3][%d]", i)) );
//        }
//        System.gc(); System.gc();
//
//        assertThat(FieldReference.DEDUP.size(), lessThan(1_000_000));
//    }

    @Test
    public void testParseSingleBareField() throws Exception {
        FieldReference f = FieldReference.from("foo");
        assertEquals(0, f.getPath().length);
        assertEquals("foo", f.getKey());
    }

    @Test
    public void testParseSingleFieldPath() throws Exception {
        FieldReference f = FieldReference.from("[foo]");
        assertEquals(0, f.getPath().length);
        assertEquals("foo", f.getKey());
    }

    @Test
    public void testParse2FieldsPath() throws Exception {
        FieldReference f = FieldReference.from("[foo][bar]");
        assertArrayEquals(new String[]{"foo"}, f.getPath());
        assertEquals("bar", f.getKey());
    }

    @Test
    public void testParse3FieldsPath() throws Exception {
        FieldReference f = FieldReference.from("[foo][bar][baz]");
        assertArrayEquals(new String[]{"foo", "bar"}, f.getPath());
        assertEquals("baz", f.getKey());
    }

    @Test
    public void testEmbeddedSingleReference() throws Exception {
        FieldReference f = FieldReference.from("[[foo]][bar]");
        assertArrayEquals(new String[]{"foo"}, f.getPath());
        assertEquals("bar", f.getKey());
    }

    @Test
    public void testEmbeddedDeepReference() throws Exception {
        FieldReference f = FieldReference.from("[[foo][bar]][baz]");
        assertArrayEquals(new String[]{"foo", "bar"}, f.getPath());
        assertEquals("baz", f.getKey());
    }

    @Test(expected=FieldReference.IllegalSyntaxException.class)
    public void testParseInvalidEmbeddedDeepReference() throws Exception {
        FieldReference f = FieldReference.from("[[foo][bar]nope][baz]");
    }

    @Test(expected=FieldReference.IllegalSyntaxException.class)
    public void testParseInvalidEmbeddedDeepReference2() throws Exception {
        FieldReference f = FieldReference.from("[nope[foo][bar]][baz]");
    }

    @Test(expected=FieldReference.IllegalSyntaxException.class)
    public void testParseInvalidNoCloseBracket() throws Exception {
        FieldReference.from("[foo][bar][baz");
    }

    @Test(expected=FieldReference.IllegalSyntaxException.class)
    public void testParseInvalidNoInitialOpenBracket() throws Exception {
        FieldReference.from("foo[bar][baz]");
    }

    @Test(expected=FieldReference.IllegalSyntaxException.class)
    public void testParseInvalidMissingMiddleBracket() throws Exception {
        FieldReference.from("[foo]bar[baz]");
    }

    @Test(expected=FieldReference.IllegalSyntaxException.class)
    public void testParseInvalidOnlyOpenBracket() throws Exception {
        FieldReference.from("[");
    }

    @Test(expected=FieldReference.IllegalSyntaxException.class)
    public void testParseInvalidOnlyCloseBracket() throws Exception {
        FieldReference.from("]");
    }

    @Test(expected=FieldReference.IllegalSyntaxException.class)
    public void testParseInvalidLotsOfOpenBrackets() throws Exception {
        FieldReference.from("[[[[[[[[[[[]");
    }

    @Test(expected=FieldReference.IllegalSyntaxException.class)
    public void testParseInvalidDoubleCloseBrackets() throws Exception {
        FieldReference.from("[foo]][bar]");
    }

    @Test(expected=FieldReference.IllegalSyntaxException.class)
    public void testParseNestingSquareBrackets() throws Exception {
        FieldReference.from("[this[is]terrible]");
    }

    @Test(expected=FieldReference.IllegalSyntaxException.class)
    public void testParseChainedNestingSquareBrackets() throws Exception {
        FieldReference.from("[this[is]terrible][and][it[should-not[work]]]");
    }

    @Test(expected=FieldReference.IllegalSyntaxException.class)
    public void testParseLiteralSquareBrackets() throws Exception {
        FieldReference.from("this[index]");
    }
}
