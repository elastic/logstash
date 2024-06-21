package org.logstash.settings;

import java.util.List;
import java.util.Objects;
import java.util.function.Predicate;

/**
 * Root class for all setting definitions.
 * */
public class Setting<T> implements Cloneable {

    private final String name;
    private final T defaultValue;
    private T value = null;
    private final boolean strict;
    private final Predicate<T> validator;
    private boolean valueIsSet = false;

    @Override
    @SuppressWarnings("unchecked")
    public Setting<T> clone() {
        try {
            Setting<T> clone = (Setting<T>) super.clone();
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

        public Setting<T> build() {
            return new Setting<>(name, defaultValue, strict, validator);
        }
    }

    public static <T> Builder<T> create(String name) {
        return new Builder<>(name);
    }

    protected Setting(String name, T defaultValue, boolean strict, Predicate<T> validator) {
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
    protected Setting<T> deprecate(String deprecatedName) {
        return new Setting<T>(deprecatedName, this.defaultValue, this.strict, this.validator);
    }

    protected static <T> Predicate<T> noValidator() {
        return t -> true;
    }

    protected void validate(T input) throws IllegalArgumentException {
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

    public void set(T newValue) {
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
        validate(this.value);
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
        return SettingWithDeprecatedAlias.wrap(this, deprecatedAlias);
    }
}



