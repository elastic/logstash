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
