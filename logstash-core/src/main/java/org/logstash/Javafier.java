/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.jruby.RubyBignum;
import org.jruby.RubyBoolean;
import org.jruby.RubyFixnum;
import org.jruby.RubyFloat;
import org.jruby.RubyNil;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.ext.bigdecimal.RubyBigDecimal;
import org.logstash.ext.JrubyTimestampExtLibrary;

public final class Javafier {

    private static final Map<Class<?>, Valuefier.Converter> CONVERTER_MAP = initConverters();

    /**
     * Javafier.deep() is called by getField.
     * When any value is added to the Event it should pass through Valuefier.convert.
     * deep(Object o) is the mechanism to pluck the Java value from a BiValue or convert a
     * ConvertedList and ConvertedMap back to ArrayList or HashMap.
     */
    private Javafier() {
    }

    public static Object deep(Object o) {
        if (o == null) {
            return null;
        }
        final Class<?> cls = o.getClass();
        final Valuefier.Converter converter = CONVERTER_MAP.get(cls);
        if (converter != null) {
            return converter.convert(o);
        }
        return fallbackConvert(o, cls);
    }

    private static Object fallbackConvert(final Object o, final Class<?> cls) {
        for (final Map.Entry<Class<?>, Valuefier.Converter> entry : CONVERTER_MAP.entrySet()) {
            if (entry.getKey().isAssignableFrom(cls)) {
                final Valuefier.Converter found = entry.getValue();
                CONVERTER_MAP.put(cls, found);
                return found.convert(o);
            }
        }
        throw new MissingConverterException(cls);
    }

    private static Map<Class<?>, Valuefier.Converter> initConverters() {
        final Map<Class<?>, Valuefier.Converter> converters =
            new ConcurrentHashMap<>(50, 0.2F, 1);
        converters.put(String.class, Valuefier.IDENTITY);
        converters.put(Float.class, Valuefier.IDENTITY);
        converters.put(RubyNil.class, value -> null);
        converters.put(Double.class, Valuefier.IDENTITY);
        converters.put(Long.class, Valuefier.IDENTITY);
        converters.put(Integer.class, Valuefier.IDENTITY);
        converters.put(Boolean.class, Valuefier.IDENTITY);
        converters.put(BigInteger.class, Valuefier.IDENTITY);
        converters.put(BigDecimal.class, Valuefier.IDENTITY);
        converters.put(Timestamp.class, Valuefier.IDENTITY);
        // Explicitly casting to RubyString or RubySymbol when we know its type for sure is faster
        // than having the JVM look up the type.
        converters.put(RubyString.class, value -> ((RubyString) value).toString());
        converters.put(RubySymbol.class, value -> ((RubySymbol) value).toString());
        converters.put(RubyBignum.class, value -> ((RubyBignum) value).getBigIntegerValue());
        converters.put(
            RubyBigDecimal.class, value -> ((RubyBigDecimal) value).getBigDecimalValue()
        );
        converters.put(RubyBoolean.class, value -> ((RubyBoolean) value).isTrue());
        converters.put(RubyFixnum.class, value -> ((RubyFixnum) value).getLongValue());
        converters.put(RubyFloat.class, value -> ((RubyFloat) value).getDoubleValue());
        converters.put(ConvertedMap.class, value -> ((ConvertedMap) value).unconvert());
        converters.put(ConvertedList.class, value -> ((ConvertedList) value).unconvert());
        converters.put(
            JrubyTimestampExtLibrary.RubyTimestamp.class,
            value -> ((JrubyTimestampExtLibrary.RubyTimestamp) value).getTimestamp()
        );
        return converters;
    }
}
