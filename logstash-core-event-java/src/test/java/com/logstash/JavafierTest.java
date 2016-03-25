package com.logstash;

import org.jruby.Ruby;
import org.jruby.RubyBignum;
import java.math.BigInteger;
import org.junit.Test;
import static org.junit.Assert.*;

public class JavafierTest {
    @Test
    public void testRubyBignum() {
        RubyBignum v = RubyBignum.newBignum(Ruby.getGlobalRuntime(), "-9223372036854776000");

        Object result = Javafier.deep(v);
        assertEquals(BigInteger.class, result.getClass());
        assertEquals( "-9223372036854776000", result.toString());
    }
}
