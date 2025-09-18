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

public class NumericSetting extends Coercible<Number> {

    public NumericSetting(String name, Number defaultValue) {
        super(name, defaultValue, true, noValidator());
    }

    // constructor used only in tests, but needs to be public to be used in Ruby spec
    public NumericSetting(String name, Number defaultValue, boolean strict) {
        super(name, defaultValue, strict, noValidator());
    }

    @Override
    public Number coerce(Object obj) {
        if (obj == null) {
            throw new IllegalArgumentException("Failed to coerce value to NumericSetting. Received null");
        }
        if (obj instanceof Number) {
            return (Number) obj;
        }
        try {
            return Integer.parseInt(obj.toString());
        } catch (NumberFormatException e) {
            // ugly flow control
        }
        try {
            return Float.parseFloat(obj.toString());
        } catch (NumberFormatException e) {
            // ugly flow control
        }

        // no integer neither float parsing succeed, invalid coercion
        throw new IllegalArgumentException(coercionFailureMessage(obj));
    }

    private String coercionFailureMessage(Object obj) {
        return String.format("Failed to coerce value to NumericSetting. Received %s (%s)", obj, obj.getClass());
    }
}
