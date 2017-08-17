package org.logstash.bivalues;

import java.math.BigDecimal;
import java.math.BigInteger;
import org.jruby.RubyBignum;
import org.jruby.RubyFixnum;
import org.jruby.RubyInteger;
import org.jruby.RubyNil;
import org.jruby.RubySymbol;
import org.jruby.ext.bigdecimal.RubyBigDecimal;
import org.jruby.javasupport.JavaUtil;
import org.junit.Test;
import org.logstash.TestBase;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;

public class BiValuesTest extends TestBase {

    @Test
    public void testBiValuesSymbolRuby() {
        String js = "double";
        RubySymbol rs = RubySymbol.newSymbol(ruby, js);
        BiValue subject = BiValues.newBiValue(rs);

        assertEquals(rs, subject.rubyValueUnconverted());
        assertEquals(rs.getClass(), subject.rubyValue(ruby).getClass());
        assertEquals(js, subject.javaValue());
        assertEquals(String.class, subject.javaValue().getClass());
    }

    @Test
    public void testBiValuesLongRuby() {
        long jo = 1234567L;
        RubyInteger ro = (RubyInteger) JavaUtil.convertJavaToUsableRubyObject(ruby, jo);
        BiValue subject = BiValues.newBiValue(ro);

        assertEquals(ro, subject.rubyValueUnconverted());
        assertEquals(ro.getClass(), subject.rubyValue(ruby).getClass());
        assertEquals(jo, subject.javaValue());
        assertEquals(Long.class, subject.javaValue().getClass());
    }

    @Test
    public void testBiValuesLongJava() {
        long jo = 1234567L;
        RubyInteger ro = (RubyInteger) JavaUtil.convertJavaToUsableRubyObject(ruby, jo);
        BiValue subject = BiValues.newBiValue(jo);

        assertEquals(jo, subject.javaValue());
        assertEquals(Long.class, subject.javaValue().getClass());
        assertEquals(ro, subject.rubyValue(ruby));
        assertEquals(ro.getClass(), subject.rubyValue(ruby).getClass());
    }

    @Test
    public void testBiValuesBigDecimalRuby() {
        BigDecimal jo = BigDecimal.valueOf(12345.678D);
        RubyBigDecimal ro = new RubyBigDecimal(ruby, ruby.getClass("BigDecimal"), jo);
        BiValue subject = BiValues.newBiValue(ro);

        assertEquals(ro, subject.rubyValueUnconverted());
        assertEquals(ro.getClass(), subject.rubyValue(ruby).getClass());
        assertEquals(jo, subject.javaValue());
        assertEquals(BigDecimal.class, subject.javaValue().getClass());
    }

    @Test
    public void testBiValuesBigDecimalJava() {
        BigDecimal jo = BigDecimal.valueOf(12345.678D);
        RubyBigDecimal ro = new RubyBigDecimal(ruby, ruby.getClass("BigDecimal"), jo);
        BiValue subject = BiValues.newBiValue(jo);

        assertEquals(jo, subject.javaValue());
        assertEquals(BigDecimal.class, subject.javaValue().getClass());
        assertEquals(ro, subject.rubyValue(ruby));
        assertEquals(ro.getClass(), subject.rubyValue(ruby).getClass());
    }

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

    @Test
    public void testBiValuesBigIntegerRuby() {
        BigInteger jo = BigInteger.valueOf(12345678L);
        RubyBignum ro = new RubyBignum(ruby, jo);
        BiValue subject = BiValues.newBiValue(ro);

        assertEquals(BigIntegerBiValue.class, subject.getClass());
        assertEquals(ro, subject.rubyValueUnconverted());
        assertEquals(ro.getClass(), subject.rubyValue(ruby).getClass());
        assertEquals(jo, subject.javaValue());
        assertEquals(BigInteger.class, subject.javaValue().getClass());
    }

    @Test
    public void testBiValuesBigIntegerJava() {
        BigInteger jo = BigInteger.valueOf(12345678L);
        RubyBignum ro = new RubyBignum(ruby, jo);
        BiValue subject = BiValues.newBiValue(jo);

        assertEquals(jo, subject.javaValue());
        assertEquals(BigInteger.class, subject.javaValue().getClass());
        assertEquals(ro, subject.rubyValue(ruby));
        assertEquals(ro.getClass(), subject.rubyValue(ruby).getClass());
    }

    // NOTE: testBiValuesIntegerRuby will map to LongBiValue
    @Test
    public void testBiValuesIntegerRuby() {
        int jo = 12345678;
        RubyInteger ro = RubyFixnum.newFixnum(ruby, jo);
        BiValue subject = BiValues.newBiValue(ro);

        assertEquals(LongBiValue.class, subject.getClass());
        assertEquals(ro, subject.rubyValueUnconverted());
        assertEquals(ro.getClass(), subject.rubyValue(ruby).getClass());
        assertEquals(12345678L, subject.javaValue());
        assertEquals(Long.class, subject.javaValue().getClass());
    }

    @Test
    public void testBiValuesIntegerJava() {
        int jo = 12345678;
        RubyInteger ro = RubyFixnum.newFixnum(ruby, jo);
        BiValue subject = BiValues.newBiValue(jo);

        assertEquals(IntegerBiValue.class, subject.getClass());
        assertEquals(jo, subject.javaValue());
        assertEquals(Integer.class, subject.javaValue().getClass());
        assertEquals(ro, subject.rubyValue(ruby));
        assertEquals(ro.getClass(), subject.rubyValue(ruby).getClass());
    }

}
