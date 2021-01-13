package org.logstash.settings;

import java.util.function.Predicate;

public class SettingSpecification<T> {

    private final String name;
    private final T defaultValue;
    private final Predicate<T> validator;
    private final boolean strict;

    public SettingSpecification(String name, T defaultValue, Predicate<T> validator) {
        this.name = name;
        this.defaultValue = defaultValue;
        this.validator = validator;
        this.strict = true;

        if (isStrict()) {
            validate(getDefaultValue());
        }
    }

    public String getName() {
        return name;
    }

    public T getDefaultValue() {
        return defaultValue;
    }

    public void validate(T value) {
        if (!this.validator.test(value)) {
            throw new IllegalArgumentException(String.format("Failed to validate setting \"%s\" with value: %s", name, value));
        }
    }

    public boolean isStrict() {
        return strict;
    }
    
    public Class<?> getKlass() {
        return defaultValue.getClass();
    }
}
