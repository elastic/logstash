package org.logstash.settings;

import java.util.Objects;
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
