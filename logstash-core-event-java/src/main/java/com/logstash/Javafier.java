package com.logstash;

import com.logstash.ext.JrubyTimestampExtLibrary;
import org.joda.time.DateTime;
import org.jruby.RubyArray;
import org.jruby.RubyBignum;
import org.jruby.RubyBoolean;
import org.jruby.RubyFixnum;
import org.jruby.RubyFloat;
import org.jruby.RubyHash;
import org.jruby.RubyInteger;
import org.jruby.RubyNil;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.RubyTime;
import org.jruby.ext.bigdecimal.RubyBigDecimal;
import org.jruby.java.proxies.JavaProxy;
import org.jruby.java.proxies.MapJavaProxy;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Javafier {
    private static final String ERR_TEMPLATE = "Missing Ruby class handling for full class name=%s, simple name=%s";
    private static final String PROXY_ERR_TEMPLATE = "Missing Ruby class handling for full class name=%s, simple name=%s, wrapped object=%s";

    private Javafier(){}

    public static List<Object> deep(IRubyObject[] a) {
        final ArrayList<Object> result = new ArrayList();

        for (IRubyObject o : a) {
            result.add(deep(o));
        }
        return result;
    }

    public static List<Object> deep(RubyArray a) {
        return deep(a.toJavaArray());
    }

    private static HashMap<String, Object> deepMap(final Map<?, ?> map) {
        final HashMap<String, Object> result = new HashMap();

        for (Map.Entry<?, ?> entry : map.entrySet()) {
            String k;
            if (entry.getKey() instanceof IRubyObject) {
                k = ((IRubyObject) entry.getKey()).asJavaString();
            } else {
                k = String.valueOf(entry.getKey());
            }
            result.put(k, deepAnything(entry.getValue()));
        }
        return result;
    }

    private static List<Object> deepList(List<Object> a) {
        final ArrayList<Object> result = new ArrayList();

        for (Object o : a) {
            result.add(deepAnything(o));
        }
        return result;
    }

    public static HashMap<String, Object> deep(RubyHash h) {
        final HashMap<String, Object> result = new HashMap();

        h.visitAll(new RubyHash.Visitor() {
            @Override
            public void visit(IRubyObject key, IRubyObject value) {
                result.put(deep(key).toString(), deep(value));
            }
        });
        return result;
    }

    private static Object deepAnything(Object o) {
        // because, although we have a Java object (from a JavaProxy??), it may have IRubyObjects inside
        if (o instanceof IRubyObject) {
            return deep((IRubyObject) o);
        }
        if (o instanceof Map) {
            return deepMap((Map) o);
        }
        if (o instanceof List) {
            return deepList((List) o);
        }
        return o;
    }

    public static String deep(RubyString s) {
        return s.asJavaString();
    }

    public static long deep(RubyInteger i) {
        return i.getLongValue();
    }

    public static long deep(RubyFixnum n) {
        return n.getLongValue();
    }

    public static double deep(RubyFloat f) {
        return f.getDoubleValue();
    }

    public static BigDecimal deep(RubyBigDecimal bd) {
        return bd.getBigDecimalValue();
    }

    public static BigInteger deep(RubyBignum bn) {
        return bn.getBigIntegerValue();
    }

    public static Timestamp deep(JrubyTimestampExtLibrary.RubyTimestamp t) {
        return t.getTimestamp();
    }

    public static boolean deep(RubyBoolean b) {
        return b.isTrue();
    }

    public static Object deep(RubyNil n) {
        return null;
    }

    public static DateTime deep(RubyTime t) {
        return t.getDateTime();
    }

    public static String deep(RubySymbol s) {
        return s.asJavaString();
    }

    public static Object deep(RubyBoolean.True b) {
        return true;
    }

    public static Object deep(RubyBoolean.False b) {
        return false;
    }

    private static Object deepJavaProxy(JavaProxy jp) {
        Object obj = JavaUtil.unwrapJavaObject(jp);
        if (obj instanceof IRubyObject[]) {
            return deep((IRubyObject[])obj);
        }
        if (obj instanceof List) {
            return deepList((List<Object>) obj);
        }
        Class cls = jp.getClass();
        throw new IllegalArgumentException(missingHandlerString(PROXY_ERR_TEMPLATE, cls.getName(), cls.getSimpleName(), obj.getClass().getName()));
    }

    public static Object deep(IRubyObject o) {
        // TODO: (colin) this enum strategy is cleaner but I am hoping that is not slower than using a instanceof cascade
        Class cls = o.getClass();
        RUBYCLASS clazz;
        try {
            clazz = RUBYCLASS.valueOf(cls.getSimpleName());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException(missingHandlerString(ERR_TEMPLATE, cls.getName(), cls.getSimpleName()));
        }

        switch(clazz) {
            case RubyArray: return deep((RubyArray)o);
            case RubyHash: return deep((RubyHash)o);
            case RubyString: return deep((RubyString)o);
            case RubyInteger: return deep((RubyInteger)o);
            case RubyFloat: return deep((RubyFloat)o);
            case RubyBigDecimal: return deep((RubyBigDecimal)o);
            case RubyTimestamp: return deep((JrubyTimestampExtLibrary.RubyTimestamp)o);
            case RubyBoolean: return deep((RubyBoolean)o);
            case RubyFixnum: return deep((RubyFixnum)o);
            case RubyBignum: return deep((RubyBignum)o);
            case RubyTime: return deep((RubyTime)o);
            case RubySymbol: return deep((RubySymbol)o);
            case RubyNil: return deep((RubyNil)o);
            case True: return deep((RubyBoolean.True)o);
            case False: return deep((RubyBoolean.False)o);
            case MapJavaProxy: return deepMap((Map)((MapJavaProxy) o).getObject());
            case ArrayJavaProxy:  return deepJavaProxy((JavaProxy) o);
            case ConcreteJavaProxy: return deepJavaProxy((JavaProxy) o);
        }

        if (o.isNil()) {
            return null;
        }

        // TODO: (colin) temporary trace to spot any unhandled types
        System.out.println(String.format(
                "***** WARN: UNHANDLED IRubyObject full class name=%s, simple name=%s java class=%s toString=%s",
                o.getMetaClass().getRealClass().getName(),
                o.getClass().getSimpleName(),
                o.getJavaClass().toString(),
                o.toString()));

        return o.toJava(o.getJavaClass());
    }

    enum RUBYCLASS {
        RubyString,
        RubyInteger,
        RubyFloat,
        RubyBigDecimal,
        RubyTimestamp,
        RubyArray,
        RubyHash,
        RubyBoolean,
        RubyFixnum,
        RubyBignum,
        RubyNil,
        RubyTime,
        RubySymbol,
        True,
        False,
        // these proxies may wrap a java collection of IRubyObject types
        MapJavaProxy,
        ArrayJavaProxy,
        ConcreteJavaProxy
    }

    private static String missingHandlerString(String fmt, String... subs) {
        return String.format(fmt, subs);
    }
}

