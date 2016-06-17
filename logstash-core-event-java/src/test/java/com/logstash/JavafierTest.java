package com.logstash;

import org.jruby.Ruby;
import org.jruby.RubyBignum;
import org.jruby.RubyClass;
import org.jruby.RubyMatchData;
import org.jruby.RubyString;
import org.jruby.java.proxies.ArrayJavaProxy;
import org.jruby.java.proxies.ConcreteJavaProxy;
import org.jruby.java.proxies.MapJavaProxy;
import org.jruby.javasupport.Java;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.ExpectedException;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;

import static org.junit.Assert.assertEquals;

public class JavafierTest {
    public static final Ruby ruby;
    static {
        ruby = Ruby.getGlobalRuntime();
    }

    @Test
    public void testRubyBignum() {
        RubyBignum v = RubyBignum.newBignum(ruby, "-9223372036854776000");

        Object result = Javafier.deep(v);
        assertEquals(BigInteger.class, result.getClass());
        assertEquals( "-9223372036854776000", result.toString());
    }

    @Test
    public void testMapJavaProxy() {
        Map<IRubyObject, IRubyObject> map = new HashMap<>();
        map.put(RubyString.newString(ruby, "foo"), RubyString.newString(ruby, "bar"));
        RubyClass proxyClass = (RubyClass) Java.getProxyClass(ruby, HashMap.class);
        MapJavaProxy mjp = new MapJavaProxy(ruby, proxyClass);
        mjp.setObject(map);

        Object result = Javafier.deep(mjp);
        assertEquals(HashMap.class, result.getClass());
        HashMap<String, Object> m = (HashMap) result;
        assertEquals("bar", m.get("foo"));
    }

    @Test
    public void testArrayJavaProxy() {
        IRubyObject[] array = new IRubyObject[]{RubyString.newString(ruby, "foo")};
        RubyClass proxyClass = (RubyClass) Java.getProxyClass(ruby, String[].class);
        ArrayJavaProxy ajp = new ArrayJavaProxy(ruby, proxyClass, array);

        Object result = Javafier.deep(ajp);
        assertEquals(ArrayList.class, result.getClass());
        List<Object> a = (ArrayList) result;
        assertEquals("foo", a.get(0));
    }

    @Test
    public void testConcreteJavaProxy() {
        List<IRubyObject> array = new ArrayList<>();
        array.add(RubyString.newString(ruby, "foo"));
        RubyClass proxyClass = (RubyClass) Java.getProxyClass(ruby, ArrayList.class);
        ConcreteJavaProxy cjp = new ConcreteJavaProxy(ruby, proxyClass, array);
        Object result = Javafier.deep(cjp);
        assertEquals(ArrayList.class, result.getClass());
        List<Object> a = (ArrayList) result;
        assertEquals("foo", a.get(0));
    }

    @Rule
    public ExpectedException exception = ExpectedException.none();

    @Test
    public void testUnhandledObject() {
        RubyMatchData md = new RubyMatchData(ruby);
        exception.expect(IllegalArgumentException.class);
        exception.expectMessage("Missing Ruby class handling for full class name=org.jruby.RubyMatchData, simple name=RubyMatchData");
        Javafier.deep(md);
    }

    @Test
    public void testUnhandledProxyObject() {
        HashSet<Integer> hs = new HashSet<>();
        hs.add(42);
        RubyClass proxyClass = (RubyClass) Java.getProxyClass(ruby, HashSet.class);
        ConcreteJavaProxy cjp = new ConcreteJavaProxy(ruby, proxyClass, hs);
        exception.expect(IllegalArgumentException.class);
        exception.expectMessage("Missing Ruby class handling for full class name=org.jruby.java.proxies.ConcreteJavaProxy, simple name=ConcreteJavaProxy, wrapped object=java.util.HashSet");
        Javafier.deep(cjp);
    }
}
