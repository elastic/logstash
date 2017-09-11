package org.logstash.bivalues;

import org.junit.Test;
import org.logstash.TestBase;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

public class BiValueTest extends TestBase {

    @Test
    public void testNullBiValueFromJava() {
        NullBiValue subject = NullBiValue.newNullBiValue();
        assertTrue(subject.hasRubyValue());
        assertTrue(subject.hasJavaValue());
        assertEquals(ruby.getNil(), subject.rubyValue(ruby));
    }
}
