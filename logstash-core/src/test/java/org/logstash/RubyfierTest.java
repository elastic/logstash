package org.logstash;

import org.jruby.RubyArray;
import org.jruby.RubyBignum;
import org.jruby.RubyFixnum;
import org.jruby.RubyFloat;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.ext.bigdecimal.RubyBigDecimal;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Test;

import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.Assert.assertEquals;

public class RubyfierTest extends TestBase {

    @Test
    public void testDeepWithString() {
        Object result = Rubyfier.deep(ruby, "foo");
        assertEquals(RubyString.class, result.getClass());
        assertEquals("foo", result.toString());
    }

    @Test
    public void testDeepMapWithString()
            throws Exception
    {
        Map data = new HashMap();
        data.put("foo", "bar");
        RubyHash rubyHash = ((RubyHash) Rubyfier.deep(ruby, data));

        // Hack to be able to retrieve the original, unconverted Ruby object from Map
        // it seems the only method providing this is internalGet but it is declared protected.
        // I know this is bad practice but I think this is practically acceptable.
        Method internalGet = RubyHash.class.getDeclaredMethod("internalGet", IRubyObject.class);
        internalGet.setAccessible(true);
        Object result = internalGet.invoke(rubyHash, JavaUtil.convertJavaToUsableRubyObject(ruby, "foo"));

        assertEquals(RubyString.class, result.getClass());
        assertEquals("bar", result.toString());
    }

    @Test
    public void testDeepListWithString()
            throws Exception
    {
        List data = new ArrayList();
        data.add("foo");

        RubyArray rubyArray = ((RubyArray)Rubyfier.deep(ruby, data));

        // toJavaArray does not newFromRubyArray inner elemenst to Java types \o/
        assertEquals(RubyString.class, rubyArray.toJavaArray()[0].getClass());
        assertEquals("foo", rubyArray.toJavaArray()[0].toString());
    }

    @Test
    public void testDeepWithInteger() {
        Object result = Rubyfier.deep(ruby, 1);
        assertEquals(RubyFixnum.class, result.getClass());
        assertEquals(1L, ((RubyFixnum)result).getLongValue());
    }

    @Test
    public void testDeepMapWithInteger()
            throws Exception
    {
        Map data = new HashMap();
        data.put("foo", 1);
        RubyHash rubyHash = ((RubyHash)Rubyfier.deep(ruby, data));

        // Hack to be able to retrieve the original, unconverted Ruby object from Map
        // it seems the only method providing this is internalGet but it is declared protected.
        // I know this is bad practice but I think this is practically acceptable.
        Method internalGet = RubyHash.class.getDeclaredMethod("internalGet", IRubyObject.class);
        internalGet.setAccessible(true);
        Object result = internalGet.invoke(rubyHash, JavaUtil.convertJavaToUsableRubyObject(ruby, "foo"));

        assertEquals(RubyFixnum.class, result.getClass());
        assertEquals(1L, ((RubyFixnum)result).getLongValue());
    }

    @Test
    public void testDeepListWithInteger()
            throws Exception
    {
        List data = new ArrayList();
        data.add(1);

        RubyArray rubyArray = ((RubyArray)Rubyfier.deep(ruby, data));

        // toJavaArray does not newFromRubyArray inner elemenst to Java types \o/
        assertEquals(RubyFixnum.class, rubyArray.toJavaArray()[0].getClass());
        assertEquals(1L, ((RubyFixnum)rubyArray.toJavaArray()[0]).getLongValue());
    }

    @Test
    public void testDeepWithFloat() {
        Object result = Rubyfier.deep(ruby, 1.0F);
        assertEquals(RubyFloat.class, result.getClass());
        assertEquals(1.0D, ((RubyFloat)result).getDoubleValue(), 0);
    }

    @Test
    public void testDeepMapWithFloat()
            throws Exception
    {
        Map data = new HashMap();
        data.put("foo", 1.0F);
        RubyHash rubyHash = ((RubyHash)Rubyfier.deep(ruby, data));

        // Hack to be able to retrieve the original, unconverted Ruby object from Map
        // it seems the only method providing this is internalGet but it is declared protected.
        // I know this is bad practice but I think this is practically acceptable.
        Method internalGet = RubyHash.class.getDeclaredMethod("internalGet", IRubyObject.class);
        internalGet.setAccessible(true);
        Object result = internalGet.invoke(rubyHash, JavaUtil.convertJavaToUsableRubyObject(ruby, "foo"));

        assertEquals(RubyFloat.class, result.getClass());
        assertEquals(1.0D, ((RubyFloat)result).getDoubleValue(), 0);
    }

    @Test
    public void testDeepListWithFloat()
            throws Exception
    {
        List data = new ArrayList();
        data.add(1.0F);

        RubyArray rubyArray = ((RubyArray)Rubyfier.deep(ruby, data));

        // toJavaArray does not newFromRubyArray inner elemenst to Java types \o/
        assertEquals(RubyFloat.class, rubyArray.toJavaArray()[0].getClass());
        assertEquals(1.0D, ((RubyFloat)rubyArray.toJavaArray()[0]).getDoubleValue(), 0);
    }

    @Test
    public void testDeepWithDouble() {
        Object result = Rubyfier.deep(ruby, 1.0D);
        assertEquals(RubyFloat.class, result.getClass());
        assertEquals(1.0D, ((RubyFloat)result).getDoubleValue(), 0);
    }

    @Test
    public void testDeepMapWithDouble()
            throws Exception
    {
        Map data = new HashMap();
        data.put("foo", 1.0D);
        RubyHash rubyHash = ((RubyHash)Rubyfier.deep(ruby, data));

        // Hack to be able to retrieve the original, unconverted Ruby object from Map
        // it seems the only method providing this is internalGet but it is declared protected.
        // I know this is bad practice but I think this is practically acceptable.
        Method internalGet = RubyHash.class.getDeclaredMethod("internalGet", IRubyObject.class);
        internalGet.setAccessible(true);
        Object result = internalGet.invoke(rubyHash, JavaUtil.convertJavaToUsableRubyObject(ruby, "foo"));

        assertEquals(RubyFloat.class, result.getClass());
        assertEquals(1.0D, ((RubyFloat)result).getDoubleValue(), 0);
    }

    @Test
    public void testDeepListWithDouble()
            throws Exception
    {
        List data = new ArrayList();
        data.add(1.0D);

        RubyArray rubyArray = ((RubyArray)Rubyfier.deep(ruby, data));

        // toJavaArray does not newFromRubyArray inner elemenst to Java types \o/
        assertEquals(RubyFloat.class, rubyArray.toJavaArray()[0].getClass());
        assertEquals(1.0D, ((RubyFloat)rubyArray.toJavaArray()[0]).getDoubleValue(), 0);
    }

    @Test
    public void testDeepWithBigDecimal() {
        Object result = Rubyfier.deep(ruby, new BigDecimal(1));
        assertEquals(RubyBigDecimal.class, result.getClass());
        assertEquals(1.0D, ((RubyBigDecimal)result).getDoubleValue(), 0);
    }

    @Test
    public void testDeepMapWithBigDecimal()
            throws Exception
    {
        Map data = new HashMap();
        data.put("foo", new BigDecimal(1));

        RubyHash rubyHash = ((RubyHash)Rubyfier.deep(ruby, data));

        // Hack to be able to retrieve the original, unconverted Ruby object from Map
        // it seems the only method providing this is internalGet but it is declared protected.
        // I know this is bad practice but I think this is practically acceptable.
        Method internalGet = RubyHash.class.getDeclaredMethod("internalGet", IRubyObject.class);
        internalGet.setAccessible(true);
        Object result = internalGet.invoke(rubyHash, JavaUtil.convertJavaToUsableRubyObject(ruby, "foo"));

        assertEquals(RubyBigDecimal.class, result.getClass());
        assertEquals(1.0D, ((RubyBigDecimal)result).getDoubleValue(), 0);
    }

    @Test
    public void testDeepListWithBigDecimal()
            throws Exception
    {
        List data = new ArrayList();
        data.add(new BigDecimal(1));

        RubyArray rubyArray = ((RubyArray)Rubyfier.deep(ruby, data));

        // toJavaArray does not newFromRubyArray inner elemenst to Java types \o/
        assertEquals(RubyBigDecimal.class, rubyArray.toJavaArray()[0].getClass());
        assertEquals(1.0D, ((RubyBigDecimal)rubyArray.toJavaArray()[0]).getDoubleValue(), 0);
    }


    @Test
    public void testDeepWithBigInteger() {
        Object result = Rubyfier.deep(ruby, new BigInteger("1"));
        assertEquals(RubyBignum.class, result.getClass());
        assertEquals(1L, ((RubyBignum)result).getLongValue());
    }

}
