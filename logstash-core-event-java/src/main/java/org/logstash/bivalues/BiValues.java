package org.logstash.bivalues;

import org.logstash.Timestamp;
import org.logstash.ext.JrubyTimestampExtLibrary.RubyTimestamp;
import org.jruby.RubyBignum;
import org.jruby.RubyBoolean;
import org.jruby.RubyFloat;
import org.jruby.RubyInteger;
import org.jruby.RubyNil;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.ext.bigdecimal.RubyBigDecimal;
import org.jruby.java.proxies.JavaProxy;
import org.jruby.runtime.builtin.IRubyObject;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.HashMap;

public enum BiValues {
    ORG_LOGSTASH_EXT_JRUBYTIMESTAMPEXTLIBRARY$RUBYTIMESTAMP(BiValueType.TIMESTAMP),
    ORG_LOGSTASH_TIMESTAMP(BiValueType.TIMESTAMP),
    JAVA_LANG_BOOLEAN(BiValueType.BOOLEAN),
    JAVA_LANG_DOUBLE(BiValueType.DOUBLE),
    JAVA_LANG_FLOAT(BiValueType.FLOAT),
    JAVA_LANG_INTEGER(BiValueType.INT),
    JAVA_LANG_LONG(BiValueType.LONG),
    JAVA_LANG_STRING(BiValueType.STRING),
    JAVA_MATH_BIGDECIMAL(BiValueType.DECIMAL),
    JAVA_MATH_BIGINTEGER(BiValueType.BIGINT),
    ORG_JRUBY_EXT_BIGDECIMAL_RUBYBIGDECIMAL(BiValueType.DECIMAL),
    ORG_JRUBY_JAVA_PROXIES_CONCRETEJAVAPROXY(BiValueType.JAVAPROXY),
    ORG_JRUBY_RUBYBIGNUM(BiValueType.BIGINT),
    ORG_JRUBY_RUBYBOOLEAN$FALSE(BiValueType.BOOLEAN),
    ORG_JRUBY_RUBYBOOLEAN$TRUE(BiValueType.BOOLEAN),
    ORG_JRUBY_RUBYBOOLEAN(BiValueType.BOOLEAN),
    ORG_JRUBY_RUBYFIXNUM(BiValueType.LONG),
    ORG_JRUBY_RUBYFLOAT(BiValueType.DOUBLE),
    ORG_JRUBY_RUBYINTEGER(BiValueType.LONG),
    ORG_JRUBY_RUBYNIL(BiValueType.NULL),
    ORG_JRUBY_RUBYSTRING(BiValueType.STRING),
    ORG_JRUBY_RUBYSYMBOL(BiValueType.SYMBOL), // one way conversion, a Java string will use STRING
    NULL(BiValueType.NULL);

    private static HashMap<String, String> initCache() {
        HashMap<String, String> hm = new HashMap<>();
        hm.put("org.logstash.Timestamp", "ORG_LOGSTASH_TIMESTAMP");
        hm.put("org.logstash.ext.JrubyTimestampExtLibrary$RubyTimestamp", "ORG_LOGSTASH_EXT_JRUBYTIMESTAMPEXTLIBRARY$RUBYTIMESTAMP");
        hm.put("java.lang.Boolean", "JAVA_LANG_BOOLEAN");
        hm.put("java.lang.Double", "JAVA_LANG_DOUBLE");
        hm.put("java.lang.Float", "JAVA_LANG_FLOAT");
        hm.put("java.lang.Integer", "JAVA_LANG_INTEGER");
        hm.put("java.lang.Long", "JAVA_LANG_LONG");
        hm.put("java.lang.String", "JAVA_LANG_STRING");
        hm.put("java.math.BigDecimal", "JAVA_MATH_BIGDECIMAL");
        hm.put("java.math.BigInteger", "JAVA_MATH_BIGINTEGER");
        hm.put("org.jruby.RubyBignum", "ORG_JRUBY_RUBYBIGNUM");
        hm.put("org.jruby.RubyBoolean", "ORG_JRUBY_RUBYBOOLEAN");
        hm.put("org.jruby.RubyBoolean$False", "ORG_JRUBY_RUBYBOOLEAN$FALSE");
        hm.put("org.jruby.RubyBoolean$True", "ORG_JRUBY_RUBYBOOLEAN$TRUE");
        hm.put("org.jruby.RubyFixnum", "ORG_JRUBY_RUBYFIXNUM");
        hm.put("org.jruby.RubyFloat", "ORG_JRUBY_RUBYFLOAT");
        hm.put("org.jruby.RubyInteger", "ORG_JRUBY_RUBYINTEGER");
        hm.put("org.jruby.RubyNil", "ORG_JRUBY_RUBYNIL");
        hm.put("org.jruby.RubyString", "ORG_JRUBY_RUBYSTRING");
        hm.put("org.jruby.RubySymbol", "ORG_JRUBY_RUBYSYMBOL");
        hm.put("org.jruby.ext.bigdecimal.RubyBigDecimal", "ORG_JRUBY_EXT_BIGDECIMAL_RUBYBIGDECIMAL");
        hm.put("org.jruby.java.proxies.ConcreteJavaProxy", "ORG_JRUBY_JAVA_PROXIES_CONCRETEJAVAPROXY");
        return hm;
    }

    private final BiValueType biValueType;

    BiValues(BiValueType biValueType) {
        this.biValueType = biValueType;
    }

    private static final HashMap<String, String> nameCache = initCache();

    private BiValue build(Object value) {
        return biValueType.build(value);
    }

    public static BiValue newBiValue(Object o) {
        if (o == null){
            return NULL.build(null);
        }
        BiValues bvs = valueOf(fetchName(o));
        return bvs.build(o);
    }

    private static String fetchName(Object o) {
        String cls = o.getClass().getName();
        if (nameCache.containsKey(cls)) {
            return nameCache.get(cls);
        }
        String toCache = cls.toUpperCase().replace('.', '_');
        // TODO[Guy] log warn that we are seeing a uncached value
        nameCache.put(cls, toCache);
        return toCache;
    }

    private enum BiValueType {
        STRING {
            BiValue build(Object value) {
                if (value instanceof IRubyObject) {
                    return new StringBiValue((RubyString) value);
                }
                return new StringBiValue((String) value);
            }
        },
        SYMBOL {
            BiValue build(Object value) {
                if (value instanceof IRubyObject) {
                    return new SymbolBiValue((RubySymbol) value);
                }
                return new SymbolBiValue((String) value);
            }
        },
        LONG {
            BiValue build(Object value) {
                if (value instanceof IRubyObject) {
                    return new LongBiValue((RubyInteger) value);
                }
                return new LongBiValue((Long) value);
            }
        },
        INT {
            BiValue build(Object value) {
                if (value instanceof IRubyObject) {
                    return new IntegerBiValue((RubyInteger) value);
                }
                return new IntegerBiValue((Integer) value);
            }
        },
        DOUBLE {
            BiValue build(Object value) {
                if (value instanceof IRubyObject) {
                    return new DoubleBiValue((RubyFloat) value);
                }
                return new DoubleBiValue((Double) value);
            }
        },
        FLOAT {
            BiValue build(Object value) {
                if (value instanceof IRubyObject) {
                    return new DoubleBiValue((RubyFloat) value);
                }
                return new FloatBiValue((Float) value);
            }
        },
        DECIMAL {
            BiValue build(Object value) {
                if (value instanceof IRubyObject) {
                    return new BigDecimalBiValue((RubyBigDecimal) value);
                }
                return new BigDecimalBiValue((BigDecimal) value);
            }
        },
        BOOLEAN {
            BiValue build(Object value) {
                if (value instanceof IRubyObject) {
                    return new BooleanBiValue((RubyBoolean) value);
                }
                return new BooleanBiValue((Boolean) value);
            }
        },
        TIMESTAMP {
            BiValue build(Object value) {
                if (value instanceof IRubyObject) {
                    return new TimestampBiValue((RubyTimestamp) value);
                }
                return new TimestampBiValue((Timestamp) value);
            }
        },
        NULL {
            BiValue build(Object value) {
                if (value instanceof IRubyObject) {
                    return new NullBiValue((RubyNil) value);
                }
                return NullBiValue.newNullBiValue();
            }
        },
        BIGINT {
            BiValue build(Object value) {
                if (value instanceof IRubyObject) {
                    return new BigIntegerBiValue((RubyBignum) value);
                }
                return new BigIntegerBiValue((BigInteger) value);
            }
        },
        JAVAPROXY {
            BiValue build(Object value) {
                if (value instanceof IRubyObject) {
                    return new JavaProxyBiValue((JavaProxy) value);
                }
                return new JavaProxyBiValue(value);
            }
        };
        abstract BiValue build(Object value);
    }

}
