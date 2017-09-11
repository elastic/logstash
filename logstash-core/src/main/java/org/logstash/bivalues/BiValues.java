package org.logstash.bivalues;

import java.util.HashMap;
import java.util.Map;
import org.jruby.RubyNil;
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
        hm.put(RubyNil.class, value -> NULL_BI_VALUE);
        hm.put(ConcreteJavaProxy.class, value -> {
            if (value instanceof JavaProxy) {
                return new JavaProxyBiValue((JavaProxy) value);
            }
            return new JavaProxyBiValue(value);
        });
        return hm;
    }
}
