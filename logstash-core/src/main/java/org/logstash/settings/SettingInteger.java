package org.logstash.settings;

public class SettingInteger extends Coercible<Integer> {

    public SettingInteger(String name, Integer defaultValue) {
        super(name, defaultValue, true, noValidator());
    }

    // constructor used only in tests, but needs to be public to be used in Ruby spec
    public SettingInteger(String name, Integer defaultValue, boolean strict) {
        super(name, defaultValue, strict, noValidator());
    }

    @Override
    public Integer coerce(Object obj) {
        if (!(obj instanceof String)) {
            // it's an Integer and cast
            if (obj instanceof Integer) {
                return (Integer) obj;
            }
        } else {
            // try to parse string to int
            try {
                return Integer.parseInt(obj.toString());
            } catch (NumberFormatException e) {
                // ugly flow control
            }
        }

        // invalid coercion
        throw new IllegalArgumentException(coercionFailureMessage(obj));
    }

    private String coercionFailureMessage(Object obj) {
        return String.format("Failed to coerce value to SettingInteger. Received %s (%s)", obj, obj.getClass());
    }
}
