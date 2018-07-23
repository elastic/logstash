package org.logstash;

import java.lang.reflect.Field;
import java.util.Map;
import org.hamcrest.CoreMatchers;
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
        FieldReferenceTest.LegacyMode.class,
        FieldReferenceTest.CompatMode.class,
        FieldReferenceTest.StrictMode.class,
})
public final class FieldReferenceTest {

    private static abstract class Base {
        FieldReference.ParsingMode previousParsingMode;

        @Before
        public void setParsingMode() {
            previousParsingMode = FieldReference.setParsingMode(parsingMode());
        }

        @Before
        public void clearParsingCache() throws Exception {
            final Field cacheField = FieldReference.class.getDeclaredField("CACHE");
            cacheField.setAccessible(true);
            final Map<CharSequence, FieldReference> cache =
                    (Map<CharSequence, FieldReference>) cacheField.get(null);
            cache.clear();
        }

        @Before
        public void clearDedupCache() throws Exception  {
            final Field cacheField = FieldReference.class.getDeclaredField("DEDUP");
            cacheField.setAccessible(true);
            final Map<CharSequence, FieldReference> cache =
                    (Map<CharSequence, FieldReference>) cacheField.get(null);
            cache.clear();
        }

        @After
        public void restoreParsingMode() {
            FieldReference.setParsingMode(previousParsingMode);
        }

        abstract FieldReference.ParsingMode parsingMode();

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
        public void testCacheUpperBound() throws NoSuchFieldException, IllegalAccessException {
            final Field cacheField = FieldReference.class.getDeclaredField("CACHE");
            cacheField.setAccessible(true);
            final Map<CharSequence, FieldReference> cache =
                    (Map<CharSequence, FieldReference>) cacheField.get(null);
            final int initial = cache.size();
            for (int i = 0; i < 10_001 - initial; ++i) {
                FieldReference.from(String.format("[array][%d]", i));
            }
            assertThat(cache.size(), CoreMatchers.is(10_000));
        }
    }

    public static class LegacyMode extends Base {
        @Override
        FieldReference.ParsingMode parsingMode() {
            return FieldReference.ParsingMode.LEGACY;
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
        public void testParseInvalid3FieldsPath() throws Exception {
            FieldReference f = FieldReference.from("[foo][bar]]baz]");
            assertArrayEquals(new String[]{"foo", "bar"}, f.getPath());
            assertEquals("baz", f.getKey());
        }

        @Test
        public void testParseInvalidNoCloseBracket() throws Exception {
            FieldReference f = FieldReference.from("[foo][bar][baz");
            assertArrayEquals(new String[]{"foo", "bar"}, f.getPath());
            assertEquals("baz", f.getKey());
        }

        @Test
        public void testParseInvalidNoInitialOpenBracket() throws Exception {
            FieldReference f = FieldReference.from("foo[bar][baz]");
            assertArrayEquals(new String[]{"foo", "bar"}, f.getPath());
            assertEquals("baz", f.getKey());
        }

        @Test
        public void testParseInvalidMissingMiddleBracket() throws Exception {
            FieldReference f = FieldReference.from("[foo]bar[baz]");
            assertArrayEquals(new String[]{"foo", "bar"}, f.getPath());
            assertEquals("baz", f.getKey());
        }

        @Test(expected=FieldReference.IllegalSyntaxException.class)
        public void testParseInvalidOnlyOpenBracket() throws Exception {
            // was: hard-crash, now strict-by-default
            FieldReference f = FieldReference.from("[");
        }

        @Test(expected=FieldReference.IllegalSyntaxException.class)
        public void testParseInvalidOnlyCloseBracket() throws Exception {
            // was: hard-crash, now strict-by-default
            FieldReference f = FieldReference.from("]");
        }

        @Test(expected=FieldReference.IllegalSyntaxException.class)
        public void testParseInvalidLotsOfOpenBrackets() throws Exception {
            // was: hard-crash, now strict-by-default
            FieldReference f = FieldReference.from("[[[[[[[[[[[]");
        }

        @Test
        public void testParseInvalidDoubleCloseBrackets() throws Exception {
            FieldReference f = FieldReference.from("[foo]][bar]");
            assertEquals(1, f.getPath().length);
            assertArrayEquals(new String[]{"foo"}, f.getPath());
            assertEquals("bar", f.getKey());
        }

        @Test
        public void testParseNestingSquareBrackets() throws Exception {
            FieldReference f = FieldReference.from("[this[is]terrible]");
            assertEquals(2, f.getPath().length);
            assertArrayEquals(new String[]{"this", "is"}, f.getPath());
            assertEquals("terrible", f.getKey());
        }

        @Test
        public void testParseChainedNestingSquareBrackets() throws Exception {
            FieldReference f = FieldReference.from("[this[is]terrible][and][it[should[not][work]]]");
            assertArrayEquals(new String[]{"this","is","terrible", "and", "it", "should", "not"}, f.getPath());
            assertEquals("work", f.getKey());
        }

        @Test
        public void testParseLiteralSquareBrackets() throws Exception {
            FieldReference f = FieldReference.from("this[index]");
            assertEquals(1, f.getPath().length);
            assertArrayEquals(new String[]{"this"}, f.getPath());
            assertEquals("index", f.getKey());
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
    }

    @Test
    public void testParseEmptyString() {
        final FieldReference emptyReference = FieldReference.from("");
        assertNotNull(emptyReference);
        assertEquals(
                emptyReference, FieldReference.from(RubyUtil.RUBY.newString(""))
        );
    }

    public static class CompatMode extends LegacyMode {
        @Override
        FieldReference.ParsingMode parsingMode() {
            return FieldReference.ParsingMode.LEGACY;
        }
    }


    public static class StrictMode extends Base {
        @Override
        FieldReference.ParsingMode parsingMode() {
            return FieldReference.ParsingMode.STRICT;
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
}
