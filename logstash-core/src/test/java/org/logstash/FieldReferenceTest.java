package org.logstash;

import java.lang.reflect.Field;
import java.util.Map;
import org.hamcrest.CoreMatchers;
import org.junit.Test;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertThat;
import static org.junit.Assert.assertTrue;

public final class FieldReferenceTest {

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
    public void testParseInvalidNoCloseBracket() throws Exception {
        FieldReference f = FieldReference.from("[foo][bar][baz");
        assertEquals(0, f.getPath().length);
        assertEquals("[foo][bar][baz", f.getKey());
    }

    @Test
    public void testParseInvalidNoInitialOpenBracket() throws Exception {
        FieldReference f = FieldReference.from("foo[bar][baz]");
        assertEquals(0, f.getPath().length);
        assertEquals("foo[bar][baz]", f.getKey());
    }

    @Test
    public void testParseInvalidMissingMiddleBracket() throws Exception {
        FieldReference f = FieldReference.from("[foo]bar[baz]");
        assertEquals(0, f.getPath().length);
        assertEquals("[foo]bar[baz]", f.getKey());
    }

    @Test
    public void testParseInvalidOnlyOpenBracket() throws Exception {
        FieldReference f = FieldReference.from("[");
        assertEquals(0, f.getPath().length);
        assertEquals("[", f.getKey());
    }

    @Test
    public void testParseInvalidOnlyCloseBracket() throws Exception {
        FieldReference f = FieldReference.from("]");
        assertEquals(0, f.getPath().length);
        assertEquals("]", f.getKey());
    }

    @Test
    public void testParseInvalidLotsOfOpenBrackets() throws Exception {
        FieldReference f = FieldReference.from("[[[[[[[[[[[]");
        assertEquals(0, f.getPath().length);
        assertEquals("[[[[[[[[[[[]", f.getKey());
    }

    @Test
    public void testParseInvalidDoubleCloseBrackets() throws Exception {
        FieldReference f = FieldReference.from("[foo]][bar]");
        assertEquals(0, f.getPath().length);
        assertEquals("[foo]][bar]", f.getKey());
    }

    @Test
    public void testParseNestingSquareBrackets() throws Exception {
        FieldReference f = FieldReference.from("[this[is]terrible]");
        assertEquals(0, f.getPath().length);
        assertEquals("this[is]terrible", f.getKey());
    }

    @Test
    public void testParseChainedNestingSquareBrackets() throws Exception {
        FieldReference f = FieldReference.from("[this[is]terrible][but][it[should[work]]]");
        assertArrayEquals(new String[]{"this[is]terrible", "but"}, f.getPath());
        assertEquals("it[should[work]]", f.getKey());
    }

    @Test
    public void testParseLiteralSquareBrackets() throws Exception {
        FieldReference f = FieldReference.from("this[index]");
        assertEquals(0, f.getPath().length);
        assertEquals("this[index]", f.getKey());
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
            emptyReference, FieldReference.from(RubyUtil.RUBY.newString("").getByteList())
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
