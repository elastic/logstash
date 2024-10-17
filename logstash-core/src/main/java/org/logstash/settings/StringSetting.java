package org.logstash.settings;

import java.util.Collections;
import java.util.List;

public class StringSetting extends BaseSetting<String> {

    private List<String> possibleStrings = Collections.emptyList();

    public StringSetting(String name, String defaultValue, boolean strict, List<String> possibleStrings) {
        super(name, strict, noValidator()); // this super doesn't call validate either if it's strict
        this.possibleStrings = possibleStrings;
        this.defaultValue = defaultValue;

        if (strict) {
            staticValidate(defaultValue, possibleStrings, name);
        }
    }

    @Override
    public void validate(String input) throws IllegalArgumentException {
        staticValidate(input, possibleStrings, this.getName());
    }

    private static void staticValidate(String input, List<String> possibleStrings, String name) {
        if (!possibleStrings.isEmpty() && !possibleStrings.contains(input)) {
            throw new IllegalArgumentException(String.format("Invalid value \"%s: %s\" . Options are: %s", name, input, possibleStrings));
        }
    }
}
