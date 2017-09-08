package org.logstash.plugin;

import org.junit.Test;

import java.util.Collections;
import java.util.Map;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.Assert.assertEquals;

public class ConstructingObjectParserTest {
    @Test
    public void testParsing() {
        ConstructingObjectParser<Example> c = new ConstructingObjectParser<>("example", Example::new);
        c.declareInteger("foo", Example::setValue);
        Map<String, Object> config = Collections.singletonMap("foo", 1);
        Example e = c.parse(config);
        assertEquals(1, e.getValue());
    }

    @Test
    public void testStringTransform() {
        AtomicReference<Object> x = new AtomicReference<>(); // a container for calling setters via lambda

        ConstructingObjectParser.<AtomicReference<Object>>stringTransform(AtomicReference::set).accept(x, "1");
        assertEquals(x.get(), "1");

        ConstructingObjectParser.<AtomicReference<Object>>stringTransform(AtomicReference::set).accept(x, 1);
        assertEquals(x.get(), "1");

        ConstructingObjectParser.<AtomicReference<Object>>stringTransform(AtomicReference::set).accept(x, 1L);
        assertEquals(x.get(), "1");

        ConstructingObjectParser.<AtomicReference<Object>>stringTransform(AtomicReference::set).accept(x, 1F);
        assertEquals(x.get(), "1.0");

        ConstructingObjectParser.<AtomicReference<Object>>stringTransform(AtomicReference::set).accept(x, 1D);
        assertEquals(x.get(), "1.0");
    }

    private class Example {
        private int i;

        int getValue() {
            return i;
        }

        void setValue(int i) {
            this.i = i;
        }
    }


}