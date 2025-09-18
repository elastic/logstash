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

public class BooleanSetting extends Coercible<java.lang.Boolean> {

    public BooleanSetting(String name, boolean defaultValue) {
        super(name, defaultValue, true, noValidator());
    }

    public BooleanSetting(String name, boolean defaultValue, boolean strict) {
        super(name, defaultValue, strict, noValidator());
    }

    @Override
    public java.lang.Boolean coerce(Object obj) {
        if (obj instanceof String) {
            switch((String) obj) {
                case "true": return true;
                case "false": return false;
                default: throw new IllegalArgumentException(coercionFailureMessage(obj));
            }
        }
        if (obj instanceof java.lang.Boolean) {
            return (java.lang.Boolean) obj;
        }
        throw new IllegalArgumentException(coercionFailureMessage(obj));
    }

    private String coercionFailureMessage(Object obj) {
        return String.format("Cannot coerce `%s` to boolean (%s)", obj, getName());
    }
}