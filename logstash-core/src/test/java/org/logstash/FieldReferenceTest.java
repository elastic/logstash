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

import java.lang.reflect.Field;
import java.util.List;
import java.util.Map;
import org.hamcrest.CoreMatchers;
import org.jruby.RubyString;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Suite;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertThat;
import static org.junit.Assert.assertTrue;

@RunWith(Suite.class)
@Suite.SuiteClasses({
        FieldReferenceTest.EscapeNone.class,
        FieldReferenceTest.EscapePercent.class,
        FieldReferenceTest.EscapeAmpersand.class,
})
public final class FieldReferenceTest {
    private static abstract class Base extends RubyTestBase {
        public abstract String getEscapeMode();

        @Before
        public void overrideGlobalEscapeMode() {
            FieldReference.setEscapeStyle(getEscapeMode());
        }
        @After
        public void restoreGlobalEscapeMode() {
            // Default value for `config.field_reference.escape_style`
            FieldReference.setEscapeStyle("none");
        }

        @Before
        @After
        public void clearInternalCaches() {
            getInternalCache("CACHE").clear();
            getInternalCache("DEDUP").clear();
            getInternalCache("RUBY_CACHE").clear();
        }

        @Test
        public void deduplicatesTimestamp() throws Exception {
            assertTrue(FieldReference.from("@timestamp") == FieldReference.from("[@timestamp]"));
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
            final Map<String, FieldReference> cache = getInternalCache("CACHE");
            final int initial = cache.size();
            for (int i = 0; i < 10_001 - initial; ++i) {
                FieldReference.from(String.format("[array][%d]", i));
            }
            assertThat(cache.size(), CoreMatchers.is(10_000));
        }

        @Test
        public void testRubyCacheUpperBound() {
            final Map<RubyString, FieldReference> cache = getInternalCache("RUBY_CACHE");
            final int initial = cache.size();
            for (int i = 0; i < 10_050 - initial; ++i) {
                final RubyString rubyString = RubyUtil.RUBY.newString(String.format("[array][%d]", i));
                FieldReference.from(rubyString);
            }
            assertThat(cache.size(), CoreMatchers.is(10_000));
        }

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

        @Test
        public void testParseMetadataParent() throws Exception {
            FieldReference f = FieldReference.from("[@metadata]");
            assertEquals(0, f.getPath().length);
            assertEquals("@metadata", f.getKey());
            assertEquals(FieldReference.META_PARENT, f.type());
        }

        @Test
        public void testParseMetadataChild() throws Exception {
            FieldReference f = FieldReference.from("[@metadata][nested][field]");
            assertEquals(1, f.getPath().length);
            assertEquals("field", f.getKey());
            assertEquals(FieldReference.META_CHILD, f.type());
        }

        @Test(expected = FieldReference.IllegalSyntaxException.class)
        public void testParseInvalidEmbeddedDeepReference() throws Exception {
            FieldReference f = FieldReference.from("[[foo][bar]nope][baz]");
        }

        @Test(expected = FieldReference.IllegalSyntaxException.class)
        public void testParseInvalidEmbeddedDeepReference2() throws Exception {
            FieldReference f = FieldReference.from("[nope[foo][bar]][baz]");
        }

        @Test(expected = FieldReference.IllegalSyntaxException.class)
        public void testParseInvalidNoCloseBracket() throws Exception {
            FieldReference.from("[foo][bar][baz");
        }

        @Test(expected = FieldReference.IllegalSyntaxException.class)
        public void testParseInvalidNoInitialOpenBracket() throws Exception {
            FieldReference.from("foo[bar][baz]");
        }

        @Test(expected = FieldReference.IllegalSyntaxException.class)
        public void testParseInvalidMissingMiddleBracket() throws Exception {
            FieldReference.from("[foo]bar[baz]");
        }

        @Test(expected = FieldReference.IllegalSyntaxException.class)
        public void testParseInvalidOnlyOpenBracket() throws Exception {
            FieldReference.from("[");
        }

        @Test(expected = FieldReference.IllegalSyntaxException.class)
        public void testParseInvalidOnlyCloseBracket() throws Exception {
            FieldReference.from("]");
        }

        @Test(expected = FieldReference.IllegalSyntaxException.class)
        public void testParseInvalidLotsOfOpenBrackets() throws Exception {
            FieldReference.from("[[[[[[[[[[[]");
        }

        @Test(expected = FieldReference.IllegalSyntaxException.class)
        public void testParseInvalidDoubleCloseBrackets() throws Exception {
            FieldReference.from("[foo]][bar]");
        }

        @Test(expected = FieldReference.IllegalSyntaxException.class)
        public void testParseNestingSquareBrackets() throws Exception {
            FieldReference.from("[this[is]terrible]");
        }

        @Test(expected = FieldReference.IllegalSyntaxException.class)
        public void testParseChainedNestingSquareBrackets() throws Exception {
            FieldReference.from("[this[is]terrible][and][it[should-not[work]]]");
        }

        @Test(expected = FieldReference.IllegalSyntaxException.class)
        public void testParseLiteralSquareBrackets() throws Exception {
            FieldReference.from("this[index]");
        }

        @SuppressWarnings("unchecked")
        private <K, V> Map<K, V> getInternalCache(final String fieldName) {
            final Field cacheField;
            try {
                cacheField = FieldReference.class.getDeclaredField(fieldName);
                cacheField.setAccessible(true);
                return (Map<K, V>) cacheField.get(null);
            } catch (NoSuchFieldException | IllegalAccessException e) {
                throw new RuntimeException(e);
            }
        }
    }

    public static class EscapeNone extends Base {

        @Override
        public String getEscapeMode() {
            return "none";
        }
    }

    public static class EscapePercent extends Base {

        @Override
        public String getEscapeMode() {
            return "percent";
        }

        @Test
        public void testReadFieldWithSquareBracketLiteralsInPath() {
            final FieldReference fr = FieldReference.from("[foo][bar%5Bbingo%5D][okay]");
            assertEquals(2, fr.getPath().length);
            assertEquals("foo", fr.getPath()[0]);
            assertEquals("bar[bingo]", fr.getPath()[1]);
            assertEquals("okay", fr.getKey());
        }

        @Test
        public void testReadFieldWithSquareBracketLiteralsInKey() {
            final FieldReference fr = FieldReference.from("[foo][okay][bar%5Bbingo%5D]");
            assertEquals(2, fr.getPath().length);
            assertEquals("foo", fr.getPath()[0]);
            assertEquals("okay", fr.getPath()[1]);
            assertEquals("bar[bingo]", fr.getKey());
        }

        @Test
        public void testReadFieldWithPercentLiteralInKey() {
            final FieldReference fr = FieldReference.from("[foo][bar][95%]");
            assertEquals(2, fr.getPath().length);
            assertEquals("foo", fr.getPath()[0]);
            assertEquals("bar", fr.getPath()[1]);
            assertEquals("95%", fr.getKey());
        }
    }

    public static class EscapeAmpersand extends Base {

        @Override
        public String getEscapeMode() {
            return "ampersand";
        }


        @Test
        public void testReadFieldWithSquareBracketLiteralsInPath() {
            final FieldReference fr = FieldReference.from("[foo][bar&#91;bingo&#93;][okay]");
            assertEquals(2, fr.getPath().length);
            assertEquals("foo", fr.getPath()[0]);
            assertEquals("bar[bingo]", fr.getPath()[1]);
            assertEquals("okay", fr.getKey());
        }

        @Test
        public void testReadFieldWithSquareBracketLiteralsInKey() {
            final FieldReference fr = FieldReference.from("[foo][okay][bar&#91;bingo&#93;]");
            assertEquals(2, fr.getPath().length);
            assertEquals("foo", fr.getPath()[0]);
            assertEquals("okay", fr.getPath()[1]);
            assertEquals("bar[bingo]", fr.getKey());
        }

        @Test
        public void testReadFieldWithAmpersandLiteralInKey() {
            final FieldReference fr = FieldReference.from("[foo][bar][this&that]");
            assertEquals(2, fr.getPath().length);
            assertEquals("foo", fr.getPath()[0]);
            assertEquals("bar", fr.getPath()[1]);
            assertEquals("this&that", fr.getKey());
        }
    }
}
