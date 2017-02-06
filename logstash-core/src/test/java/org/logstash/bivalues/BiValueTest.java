package org.logstash.bivalues;

import org.logstash.TestBase;
import org.joda.time.DateTime;
import org.jruby.RubyBignum;
import org.jruby.RubyBoolean;
import org.jruby.RubyFixnum;
import org.jruby.RubyFloat;
import org.jruby.RubyInteger;
import org.jruby.RubyNil;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.RubyTime;
import org.jruby.ext.bigdecimal.RubyBigDecimal;
import org.junit.Test;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.math.BigDecimal;
import java.math.BigInteger;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

public class BiValueTest extends TestBase {
    @Test
    public void testStringBiValueFromRuby() {
        String s = "foo bar baz";
        StringBiValue subject = new StringBiValue(RubyString.newString(ruby, s));
        assertTrue(subject.hasRubyValue());
        assertFalse(subject.hasJavaValue());
        assertEquals(s, subject.javaValue());
    }

    @Test
    public void testStringBiValueFromJava() {
        RubyString v = RubyString.newString(ruby, "foo bar baz");
        StringBiValue subject = new StringBiValue("foo bar baz");
        assertFalse(subject.hasRubyValue());
        assertTrue(subject.hasJavaValue());
        assertEquals(v, subject.rubyValue(ruby));
    }

    @Test
    public void testSymbolBiValueFromRuby() {
        String s = "foo";
        SymbolBiValue subject = new SymbolBiValue(RubySymbol.newSymbol(ruby, s));
        assertTrue(subject.hasRubyValue());
        assertFalse(subject.hasJavaValue());
        assertEquals(s, subject.javaValue());
    }

    @Test
    public void testLongBiValueFromRuby() {
        Long s = 123456789L;
        LongBiValue subject = new LongBiValue(RubyFixnum.newFixnum(ruby, s));
        assertTrue(subject.hasRubyValue());
        assertFalse(subject.hasJavaValue());
        assertEquals(s, subject.javaValue());
    }

    @Test
    public void testLongBiValueFromJava() {
        RubyInteger v = RubyFixnum.newFixnum(ruby, 123456789L);
        LongBiValue subject = new LongBiValue(123456789L);
        assertFalse(subject.hasRubyValue());
        assertTrue(subject.hasJavaValue());
        assertEquals(v, subject.rubyValue(ruby));
    }


    @Test
    public void testIntegerBiValueFromRuby() {
        int j = 123456789;
        IntegerBiValue subject = new IntegerBiValue(RubyFixnum.newFixnum(ruby, j));
        assertTrue(subject.hasRubyValue());
        assertFalse(subject.hasJavaValue());
        assertTrue(j - subject.javaValue() == 0);
    }

    @Test
    public void testIntegerBiValueFromJava() {
        RubyInteger v = RubyFixnum.newFixnum(ruby, 123456789);
        IntegerBiValue subject = new IntegerBiValue(123456789);
        assertFalse(subject.hasRubyValue());
        assertTrue(subject.hasJavaValue());
        assertEquals(v, subject.rubyValue(ruby));
    }

    @Test
    public void testBigDecimalBiValueFromRuby() {
        BigDecimal s = BigDecimal.valueOf(12345.678D);
        BigDecimalBiValue subject = new BigDecimalBiValue(new RubyBigDecimal(ruby, s));
        assertTrue(subject.hasRubyValue());
        assertFalse(subject.hasJavaValue());
        assertEquals(s, subject.javaValue());
    }

    @Test
    public void testBigDecimalBiValueFromJava() {
        RubyBigDecimal v = new RubyBigDecimal(ruby, new BigDecimal(12345.678D));
        BigDecimalBiValue subject = new BigDecimalBiValue(new BigDecimal(12345.678D));
        assertFalse(subject.hasRubyValue());
        assertTrue(subject.hasJavaValue());
        assertEquals(v, subject.rubyValue(ruby));
    }

    @Test
    public void testDoubleBiValueFromRuby() {
        Double s = 12345.678D;
        DoubleBiValue subject = new DoubleBiValue(RubyFloat.newFloat(ruby, 12345.678D));
        assertTrue(subject.hasRubyValue());
        assertFalse(subject.hasJavaValue());
        assertEquals(s, subject.javaValue());
    }

    @Test
    public void testDoubleBiValueFromJava() {
        RubyFloat v = RubyFloat.newFloat(ruby, 12345.678D);
        DoubleBiValue subject = new DoubleBiValue(12345.678D);
        assertFalse(subject.hasRubyValue());
        assertTrue(subject.hasJavaValue());
        assertEquals(v, subject.rubyValue(ruby));
    }

    @Test
    public void testBooleanBiValueFromRuby() {
        BooleanBiValue subject = new BooleanBiValue(RubyBoolean.newBoolean(ruby, true));
        assertTrue(subject.hasRubyValue());
        assertFalse(subject.hasJavaValue());
        assertTrue(subject.javaValue());
    }

    @Test
    public void testBooleanBiValueFromJava() {
        RubyBoolean v = RubyBoolean.newBoolean(ruby, true);
        BooleanBiValue subject = new BooleanBiValue(true);
        assertFalse(subject.hasRubyValue());
        assertTrue(subject.hasJavaValue());
        assertEquals(v, subject.rubyValue(ruby));
    }

    @Test
    public void testNullBiValueFromRuby() {
        NullBiValue subject = new NullBiValue((RubyNil) ruby.getNil());
        assertTrue(subject.hasRubyValue());
        assertTrue(subject.hasJavaValue());
        assertEquals(null, subject.javaValue());
    }

    @Test
    public void testNullBiValueFromJava() {
        NullBiValue subject = NullBiValue.newNullBiValue();
        assertFalse(subject.hasRubyValue());
        assertTrue(subject.hasJavaValue());
        assertEquals(ruby.getNil(), subject.rubyValue(ruby));
    }

    @Test
    public void testTimeBiValueFromRuby() {
        DateTime t = DateTime.now();
        RubyTime now = RubyTime.newTime(ruby, t);
        TimeBiValue subject = new TimeBiValue(now);
        assertTrue(subject.hasRubyValue());
        assertFalse(subject.hasJavaValue());
        assertEquals(t, subject.javaValue());
    }

    @Test
    public void testTimeBiValueFromJava() {
        DateTime t = DateTime.now();
        TimeBiValue subject = new TimeBiValue(t);
        assertFalse(subject.hasRubyValue());
        assertTrue(subject.hasJavaValue());
        assertEquals(RubyTime.newTime(ruby, t), subject.rubyValue(ruby));
    }

    @Test
    public void testBigIntegerBiValueFromRuby() {
        BigInteger s = BigInteger.valueOf(12345678L);
        BigIntegerBiValue subject = new BigIntegerBiValue(new RubyBignum(ruby, s));
        assertTrue(subject.hasRubyValue());
        assertFalse(subject.hasJavaValue());
        assertEquals(s, subject.javaValue());
    }

    @Test
    public void testBigIntegerBiValueFromJava() {
        RubyBignum v = new RubyBignum(ruby, BigInteger.valueOf(12345678L));
        BigIntegerBiValue subject = new BigIntegerBiValue(BigInteger.valueOf(12345678L));
        assertFalse(subject.hasRubyValue());
        assertTrue(subject.hasJavaValue());
        assertEquals(v, subject.rubyValue(ruby));
    }

    @Test
    public void testSerialization() throws Exception {
        RubyBignum v = RubyBignum.newBignum(ruby, "-9223372036854776000");
        BiValue original = BiValues.newBiValue(v);

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ObjectOutputStream oos = new ObjectOutputStream(baos);
        oos.writeObject(original);
        oos.close();

        ByteArrayInputStream bais = new ByteArrayInputStream(baos.toByteArray());
        ObjectInputStream ois = new ObjectInputStream(bais);
        BiValue copy = (BiValue) ois.readObject();
        assertEquals(original, copy);
        assertFalse(copy.hasRubyValue());
    }
}