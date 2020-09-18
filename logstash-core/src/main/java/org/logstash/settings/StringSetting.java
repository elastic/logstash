package org.logstash.settings;

import java.util.Collections;
import java.util.List;
import java.util.function.Predicate;

public class StringSetting extends Setting {

    public static class Builder {
        private final String name;
        private Object defaultValue = null;
        private boolean strict = true;
        private List<String> possibleStrings = Collections.emptyList();

        public Builder(String name) {
            this.name = name;
        }

        public Builder defaultValue(Object defaultValue) {
            this.defaultValue = defaultValue;
            return this;
        }

        public Builder strict(boolean strict) {
            this.strict = strict;
            return this;
        }

        public Builder possibleStrings(List<String> possibleStrings) {
            this.possibleStrings = possibleStrings;
            return this;
        }

        public StringSetting build() {
            return new StringSetting(name, defaultValue, strict, possibleStrings);
        }
    }

    private List<String> possibleStrings;

    private StringSetting(String name, Object defaultValue, boolean strict, List<String> possibleStrings) {
        this(name, java.lang.String.class, defaultValue, strict);
        this.possibleStrings = possibleStrings;
    }

    // inherited
    public StringSetting(String name, Class<? extends Object> klass, Object defaultValue, boolean strict) {
        super(name, klass, defaultValue, strict);
    }

    public StringSetting(String name, Class<? extends Object> klass, Object defaultValue, boolean strict, Predicate<Object> validator) {
        super(name, klass, defaultValue, strict, validator);
    }

    @Override
    protected void validate(Object value) {
        super.validate(value);
        if (!(possibleStrings.isEmpty() || possibleStrings.contains(value))) {
            throw new IllegalArgumentException("Invalid value " + value + ". Options are: " + possibleStrings);
        }
    }

}
