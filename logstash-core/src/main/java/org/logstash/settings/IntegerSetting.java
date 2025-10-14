package org.logstash.settings;

import java.util.function.Predicate;

public class IntegerSetting extends Coercible<Integer> {

    public IntegerSetting(String name, Integer defaultValue) {
        super(name, defaultValue, true, noValidator());
    }

    // constructor used only in tests, but needs to be public to be used in Ruby spec
    public IntegerSetting(String name, Integer defaultValue, boolean strict) {
        super(name, defaultValue, strict, noValidator());
    }

    // Exposed to be redefined in subclasses
    protected IntegerSetting(String name, Integer defaultValue, boolean strict, Predicate<Integer> validator) {
        super(name, defaultValue, strict, validator);
    }

    @Override
    public Integer coerce(Object obj) {
        if (!(obj instanceof String)) {
            // it's an Integer and cast
            if (obj instanceof Integer) {
                return (Integer) obj;
            }
            // JRuby bridge convert ints to Long
            if (obj instanceof Long) {
                return ((Long) obj).intValue();
            }
        } else {
            // try to parse string to int
            try {
                return Integer.parseInt(obj.toString().trim());
            } catch (NumberFormatException e) {
                // ugly flow control
            }
        }

        // invalid coercion
        throw new IllegalArgumentException(coercionFailureMessage(obj));
    }

    private String coercionFailureMessage(Object obj) {
        return String.format("Failed to coerce value to IntegerSetting. Received %s (%s)", obj, obj.getClass());
    }
}
