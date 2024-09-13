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

import java.util.function.Predicate;

public abstract class Coercible<T> extends Setting<T> {
    public Coercible(String name, T defaultValue, boolean strict, Predicate<T> validator) {
        super(name, strict, validator);

        if (strict) {
            T coercedDefault = coerce(defaultValue);
            validate(coercedDefault);
            this.defaultValue = coercedDefault;
        } else {
            this.defaultValue = defaultValue;
        }
    }

    @Override
    public void set(T value) {
        T coercedValue = coerce(value);
        validate(coercedValue);
        super.set(coercedValue);
    }

    public abstract T coerce(Object obj);
}
