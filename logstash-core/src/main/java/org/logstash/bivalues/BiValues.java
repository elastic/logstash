package org.logstash.bivalues;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.HashMap;
import java.util.Map;
import org.jruby.RubyBignum;
import org.jruby.RubyNil;
import org.jruby.RubySymbol;
import org.jruby.ext.bigdecimal.RubyBigDecimal;
import org.jruby.java.proxies.ConcreteJavaProxy;
import org.jruby.java.proxies.JavaProxy;

public final class BiValues {
    private BiValues() {
    }

    public static final NullBiValue NULL_BI_VALUE = NullBiValue.newNullBiValue();

    private static final Map<Class<?>, BiValues.BiValueType> CONVERTER_CACHE = initCache();

    public static BiValue newBiValue(Object o) {
        if (o == null) {
            return NULL_BI_VALUE;
        }
        final Class<?> cls = o.getClass();
        final BiValues.BiValueType type = CONVERTER_CACHE.get(cls);
        if (type == null) {
            throw new IllegalArgumentException(
                String.format(
                    "Missing Converter handling for full class name=%s, simple name=%s",
                    cls.getName(), cls.getSimpleName()
                )
            );
        }
        return type.build(o);
    }

    private interface BiValueType {
        BiValue build(Object value);
    }

    private static Map<Class<?>, BiValues.BiValueType> initCache() {
        final Map<Class<?>, BiValues.BiValueType> hm = new HashMap<>(50, 0.2F);
        hm.put(BigDecimal.class, value -> new BigDecimalBiValue((BigDecimal) value));
        hm.put(BigInteger.class, value -> new BigIntegerBiValue((BigInteger) value));
        hm.put(RubyBignum.class, value -> new BigIntegerBiValue((RubyBignum) value));
        hm.put(RubyNil.class, value -> NULL_BI_VALUE);
        hm.put(RubySymbol.class, value -> new SymbolBiValue((RubySymbol) value));
        hm.put(RubyBigDecimal.class, value -> new BigDecimalBiValue((RubyBigDecimal) value));
        hm.put(ConcreteJavaProxy.class, value -> {
            if (value instanceof JavaProxy) {
                return new JavaProxyBiValue((JavaProxy) value);
            }
            return new JavaProxyBiValue(value);
        });
        return hm;
    }
}
