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
package org.logstash.settings;

import org.logstash.util.ByteValue;

import java.math.BigInteger;

/**
 * A setting that represents a byte size value.
 * Accepts strings with byte units (e.g., "64mb", "1gb") or numeric values.
 */
public class BytesSetting extends Coercible<Number> {

    public BytesSetting(String name, String defaultValue) {
        super(name, coerceToNumber(defaultValue), true, BytesSetting::isValid);
    }

    public BytesSetting(String name, Number defaultValue) {
        super(name, defaultValue, true, BytesSetting::isValid);
    }

    // Constructor for testing with strict parameter
    public BytesSetting(String name, String defaultValue, boolean strict) {
        super(name, coerceToNumber(defaultValue), strict, BytesSetting::isValid);
    }

    private static boolean isValid(Number value) {
        if (value == null) {
            return false;
        }
        if (value instanceof BigInteger) {
            return ((BigInteger) value).compareTo(BigInteger.ZERO) >= 0;
        }
        return value.longValue() >= 0;
    }

    /**
     * Static helper to coerce String to Number for constructor use.
     */
    private static Number coerceToNumber(Object obj) {
        if (obj == null) {
            throw new IllegalArgumentException("Could not coerce 'null' into a bytes value");
        }
        if (obj instanceof Number) {
            return (Number) obj;
        }
        if (obj instanceof String) {
            BigInteger parsed;
            try {
                parsed = ByteValue.parse((String) obj);
            } catch (org.jruby.exceptions.ArgumentError e) {
                throw new IllegalArgumentException("Could not coerce '" + obj + "' into a bytes value", e);
            }
            // Return Long if it fits, otherwise return BigInteger
            if (parsed.compareTo(BigInteger.valueOf(Long.MAX_VALUE)) <= 0 &&
                parsed.compareTo(BigInteger.valueOf(Long.MIN_VALUE)) >= 0) {
                return parsed.longValue();
            }
            return parsed;
        }
        throw new IllegalArgumentException("Could not coerce '" + obj + "' into a bytes value");
    }

    @Override
    public Number coerce(Object obj) {
        return coerceToNumber(obj);
    }

    @Override
    public void validate(Number input) throws IllegalArgumentException {
        if (!isValid(input)) {
            throw new IllegalArgumentException("Invalid byte value \"" + input + "\".");
        }
    }
}
