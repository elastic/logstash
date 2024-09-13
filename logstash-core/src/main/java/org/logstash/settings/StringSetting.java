package org.logstash.settings;

import java.util.Collections;
import java.util.List;
import java.util.function.Predicate;

public class StringSetting extends Setting<String> {

    public StringSetting(String name) {
        this(name, null);
    }

    public StringSetting(String name, String defaultValue) {
        this(name, defaultValue, true);
    }

    public StringSetting(String name, String defaultValue, boolean strict) {
        this(name, defaultValue, strict, Collections.<String>emptyList());
    }

    public StringSetting(String name, String defaultValue, boolean strict, List<String> possibleStrings) {
        this(name, defaultValue, strict, s -> possibleStrings.isEmpty() || possibleStrings.contains(s));
    }

    protected StringSetting(String name, String defaultValue, boolean strict, Predicate<String> validator) {
        super(name, defaultValue, strict, validator);
    }

    @Override
    protected void validate(String input) throws IllegalArgumentException {
        try {
            super.validate(input);
        } catch (IllegalArgumentException ex) {
            String formattedError = String.format("Invalid value \"%s: %s\". Options are: #{@possible_strings.inspect}",
                    getName(), value());
            throw new IllegalArgumentException(formattedError);
        }
    }
}
