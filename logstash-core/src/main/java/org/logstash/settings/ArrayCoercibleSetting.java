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

import java.util.*;
import java.util.function.Predicate;

public class ArrayCoercibleSetting extends Coercible<Object> {

    private final Class<?> elementClass;

    @SuppressWarnings("this-escape")
    public ArrayCoercibleSetting(String name, Class<?> elementClass, Object defaultValue, boolean strict,
                                 Predicate<Object> validator) {
        super(name, defaultValue, false, validator);
        this.elementClass = elementClass;

        if (strict) {
            List<?> coercedDefault = coerce(defaultValue);
            validate(coercedDefault);
            this.defaultValue = coercedDefault;
        } else {
            this.defaultValue = defaultValue;
        }
    }

    public ArrayCoercibleSetting(String name, Class<?> elementClass, Object defaultValue, boolean strict) {
        this(name, elementClass, defaultValue, strict, noValidator());
    }

    public ArrayCoercibleSetting(String name, Class<?> elementClass, Object defaultValue) {
        this(name, elementClass, defaultValue, true);
    }

    @Override
    public List<?> coerce(Object value) {
        if (value == null) {
            return Collections.emptyList();
        }
        if (value instanceof List) {
            // We need to move away from RubyArray instances, because they equals method does a strong type checking.
            // See https://github.com/jruby/jruby/blob/9.4.14.0/core/src/main/java/org/jruby/RubyArray.java#L5988-L5994
            // If a RubyArray is compared to something else that's not a RubyArray, return false, but this doesn't
            // take care of cases when it's compared to a List, which is the case for our settings.
            // So we need to create a new ArrayList with the same content.
            return new ArrayList<>((List<?>) value);
        }
        if (value instanceof Object[]) {
            return Arrays.asList((Object[]) value);
        }
        return Collections.singletonList(value);
    }

    @Override
    public void validate(Object input) throws IllegalArgumentException {
        super.validate(input);

        if (input == null) {
            return;
        }

        List<?> inputList = (List<?>) input;
        for (Object element : inputList) {
            if (!elementClass.isInstance(element)) {
                throw new IllegalArgumentException(
                    String.format("Values of setting \"%s\" must be %s. Received: %s (%s)",
                        getName(), elementClass.getSimpleName(), element,
                        element != null ? element.getClass().getSimpleName() : "null"));
            }
        }
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }

        ArrayCoercibleSetting that = (ArrayCoercibleSetting) o;
        return this.value().equals(that.value());
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(this.value());
    }
}
