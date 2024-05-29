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
            // TODO: copy mutable state here, so the clone can't change the internals of the original
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
}

//abstract class Coercible<T> extends Setting<T> {
//
//    Coercible(String name, T defaultValue) {
//        super(name, defaultValue);
//    }
//
//    protected Coercible(String name, T defaultValue, Predicate<T> validator) {
//        super(name, defaultValue, validator);
//    }
//
//    protected Coercible(String name, T defaultValue, boolean strict, Predicate<T> validator) {
//        super(name, defaultValue, strict, validator);
//    }
//
//    abstract T coerce(String value);
//
//    public void set(String value) {
//        set(coerce(value));
//    }
//}
//
//
//class BooleanSetting extends Coercible<Boolean> {
//
//    BooleanSetting(String name, Boolean defaultValue) {
//        super(name, defaultValue);
//    }
//
//    protected BooleanSetting(String name, Boolean defaultValue, Predicate<Boolean> validator) {
//        super(name, defaultValue, validator);
//    }
//
//    protected BooleanSetting(String name, Boolean defaultValue, boolean strict, Predicate<Boolean> validator) {
//        super(name, defaultValue, strict, validator);
//    }
//
//    @Override
//    Boolean coerce(String value) {
//        if ("true".equalsIgnoreCase(value)) {
//            return true;
//        }
//        if ("false".equalsIgnoreCase(value)) {
//            return false;
//        }
//        throw new IllegalArgumentException("could not coerce " + value + " into a boolean");
//    }
//}
//
//class Numeric extends Coercible<Number> {
//
//    public Numeric(String name, Number defaultValue) {
//        super(name, defaultValue);
//    }
//
//    public Numeric(String name, Number defaultValue, boolean strict) {
//        super(name, defaultValue, strict, noValidator());
//    }
//
//    @Override
//    Number coerce(String value) {
//        try {
//            return Integer.parseInt(value);
//        } catch (NumberFormatException ex) {}
//
//        try {
//            return Double.parseDouble(value);
//        } catch (NumberFormatException ex) {}
//
//        // can't be parsed into int of double
//        throw new IllegalArgumentException("Failed to coerce value to Numeric. Received " + value);
//    }
//}
//
//class IntegerSetting extends Coercible<Integer> {
//
//    public IntegerSetting(String name, Integer defaultValue) {
//        super(name, defaultValue);
//    }
//
//    public IntegerSetting(String name, Integer defaultValue, Predicate<Integer> validator) {
//        super(name, defaultValue, validator);
//    }
//
//    public IntegerSetting(String name, Integer defaultValue, boolean strict, Predicate<Integer> validator) {
//        super(name, defaultValue, strict, validator);
//    }
//
//    @Override
//    Integer coerce(String value) {
//        try {
//            return Integer.parseInt(value);
//        } catch (NumberFormatException ex) {}
//
//        // can't be parsed into int of double
//        throw new IllegalArgumentException("Failed to coerce value to Integer. Received " + value);
//    }
//}
//
//class PositiveInteger extends IntegerSetting {
//    public PositiveInteger(String name, Integer defaultValue) {
//        super(name, defaultValue, true, new Predicate<Integer>() {
//            @Override
//            public boolean test(Integer v) {
//                if (v > 0) {
//                    return true;
//                }
//                throw new IllegalArgumentException("Number must be bigger than 0. Received: " + v);
//            }
//        });
//    }
//}
//
//class Port extends IntegerSetting {
//
//    public Port(String name, Integer defaultValue) {
//        super(name, defaultValue);
//    }
//}



