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

import java.util.List;
import java.util.Objects;
import java.util.function.Predicate;

/**
 * Root class for all setting definitions.
 * */
public class BaseSetting<T> implements Setting<T> {

    private String name; // not final because can be updated by deprecate
    T defaultValue;
    private T value = null;
    private final boolean strict;
    private final Predicate<T> validator;
    private boolean valueIsSet = false;

    @Override
    @SuppressWarnings("unchecked")
    public BaseSetting<T> clone() {
        try {
            BaseSetting<T> clone = (BaseSetting<T>) super.clone();
            // copy mutable state here, so the clone can't change the internals of the original
            clone.value = value;
            clone.valueIsSet = valueIsSet;
            return clone;
        } catch (CloneNotSupportedException e) {
            throw new AssertionError();
        }
    }

    public static final class Builder<T> {
        private final String name;
        private boolean strict = true;
        private T defaultValue = null;
        private Predicate<T> validator = noValidator();

        public Builder(String name) {
            this.name = name;
        }

        public Builder<T> defaultValue(T defaultValue) {
            this.defaultValue = defaultValue;
            return this;
        }

        public Builder<T> strict(boolean strict) {
            this.strict = strict;
            return this;
        }

        public Builder<T> validator(Predicate<T> validator) {
            this.validator = validator;
            return this;
        }

        public BaseSetting<T> build() {
            return new BaseSetting<>(name, defaultValue, strict, validator);
        }
    }

    public static <T> Builder<T> create(String name) {
        return new Builder<>(name);
    }

    /**
     * Specifically used by Coercible subclass to initialize doing validation in a second phase.
     * */
    protected BaseSetting(String name, boolean strict, Predicate<T> validator) {
        Objects.requireNonNull(name);
        Objects.requireNonNull(validator);
        this.name = name;
        this.strict = strict;
        this.validator = validator;
    }

    @SuppressWarnings("this-escape")
    protected BaseSetting(String name, T defaultValue, boolean strict, Predicate<T> validator) {
        Objects.requireNonNull(name);
        Objects.requireNonNull(validator);
        this.name = name;
        this.defaultValue = defaultValue;
        this.strict = strict;
        this.validator = validator;
        if (strict) {
           validate(defaultValue);
        }
    }

    /**
     * Creates a copy of the setting with the original name to deprecate
     * */
    protected BaseSetting<T> deprecate(String deprecatedName) {
        // this force to get a copy of the original Setting, in case of a BooleanSetting it retains also all of its
        // coercing mechanisms
        BaseSetting<T> clone = this.clone();
        clone.updateName(deprecatedName);
        return clone;
    }

    private void updateName(String deprecatedName) {
        this.name = deprecatedName;
    }

    protected static <T> Predicate<T> noValidator() {
        return t -> true;
    }

    public void validate(T input) throws IllegalArgumentException {
        if (!validator.test(input)) {
            throw new IllegalArgumentException("Failed to validate setting " + this.name + " with value: " + input);
        }
    }

    public String getName() {
        return name;
    }

    public T value() {
        if (valueIsSet) {
            return value;
        } else {
            return defaultValue;
        }
    }

    public boolean isSet() {
        return this.valueIsSet;
    }

    public boolean isStrict() {
        return strict;
    }

    public void setSafely(T newValue) {
        if (strict) {
            validate(newValue);
        }
        this.value = newValue;
        this.valueIsSet = true;
    }

    public void reset() {
        this.value = null;
        this.valueIsSet = false;
    }

    public void validateValue() {
        validate(this.value());
    }

    public T getDefault() {
        return this.defaultValue;
    }

    public void format(List<String> output) {
        T effectiveValue = this.value;
        String settingName = this.name;

        if (effectiveValue != null && effectiveValue.equals(defaultValue)) {
            // print setting and its default value
            output.add(String.format("%s: %s", settingName, effectiveValue));
        } else if (defaultValue == null) {
            // print setting and warn it has been set
            output.add(String.format("*%s: %s", settingName, effectiveValue));
        } else if (effectiveValue == null) {
            // default setting not set by user
            output.add(String.format("%s: %s", settingName, defaultValue));
        } else {
            // print setting, warn it has been set, and show default value
            output.add(String.format("*%s: %s (default: %s)", settingName, effectiveValue, defaultValue));
        }
    }

    public List<Setting<T>> withDeprecatedAlias(String deprecatedAlias) {
        return withDeprecatedAlias(deprecatedAlias, null);
    }
    public List<Setting<T>> withDeprecatedAlias(String deprecatedAlias, String obsoletedVersion) {
        return SettingWithDeprecatedAlias.wrap(this, deprecatedAlias, obsoletedVersion);
    }

    public Setting<T> nullable() {
        return new NullableSetting<>(this);
    }
 }



