package org.logstash;

import org.jruby.RubyBignum;
import org.junit.Test;

import java.math.BigInteger;
import static org.junit.Assert.assertEquals;

public class JavafierTest {

    @Test
    public void testRubyBignum() {
        RubyBignum v = RubyBignum.newBignum(RubyUtil.RUBY, "-9223372036854776000");

        Object result = Javafier.deep(v);
        assertEquals(BigInteger.class, result.getClass());
        assertEquals( "-9223372036854776000", result.toString());
    }
}
