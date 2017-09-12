package org.logstash.bivalues;

import org.jruby.RubyNil;
import org.junit.Test;
import org.logstash.TestBase;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;

public class BiValuesTest extends TestBase {

    @Test
    public void testBiValuesNilRuby() {
        RubyNil ro = (RubyNil) ruby.getNil();
        BiValue subject = BiValues.newBiValue(ro);

        assertEquals(ro, subject.rubyValueUnconverted());
        assertEquals(ro.getClass(), subject.rubyValue(ruby).getClass());
        assertNull(subject.javaValue());
    }

    @Test
    public void testBiValuesNullJava() {
        RubyNil ro = (RubyNil) ruby.getNil();
        BiValue subject = BiValues.newBiValue(null);

        assertNull(subject.javaValue());
        assertEquals(ro, subject.rubyValue(ruby));
        assertEquals(ro.getClass(), subject.rubyValue(ruby).getClass());
    }
}
