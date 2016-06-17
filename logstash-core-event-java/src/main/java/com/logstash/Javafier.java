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

public class Javafier {

    private Javafier(){}

    public static List<Object> deep(IRubyObject[] a) {
        final ArrayList<Object> result = new ArrayList();

        for (IRubyObject o : a) {
            result.add(deep(o));
        }
        return result;
    }

    public static List<Object> deep(RubyArray a) {
        return deep( a.toJavaArray());
    }

    public static List<Object> deepList(List<Object> a) {
        final ArrayList<Object> result = new ArrayList();

        for (Object o : a) {
            if (o instanceof IRubyObject) {
                result.add(deep((IRubyObject)o));
            } else {
                result.add(o);
            }
        }
        return result;
    }

    public static HashMap<String, Object> deep(RubyHash h) {
        final HashMap result = new HashMap();

        h.visitAll(new RubyHash.Visitor() {
            @Override
            public void visit(IRubyObject key, IRubyObject value) {
                result.put(deep(key).toString(), deep(value));
            }
        });
        return result;
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

    public static Object deep(IRubyObject o) {
        // TODO: (colin) this enum strategy is cleaner but I am hoping that is not slower than using a instanceof cascade

        RUBYCLASS clazz;
        try {
            clazz = RUBYCLASS.valueOf(o.getClass().getSimpleName());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Missing Ruby class handling for full class name=" + o.getClass().getName() + ", simple name=" + o.getClass().getSimpleName());
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
            case MapJavaProxy: return deep(((MapJavaProxy) o).to_hash());
            case ArrayJavaProxy:
            case ConcreteJavaProxy:
                Object obj = JavaUtil.unwrapJavaObject(o);
                if (obj instanceof IRubyObject[]) {
                    return deep((IRubyObject[])obj);
                }
                if (obj instanceof List) {
                    return deepList((List<Object>) obj);
                }
        }

        if (o.isNil()) {
            return null;
        }

        // TODO: (colin) temporary trace to spot any unhandled types
        System.out.println("***** WARN: UNHANDLED IRubyObject full class name=" + o.getMetaClass().getRealClass().getName() + ", simple name=" + o.getClass().getSimpleName() + " java class=" + o.getJavaClass().toString() + " toString=" + o.toString());

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
        MapJavaProxy,
        ArrayJavaProxy,
        ConcreteJavaProxy
    }
}

