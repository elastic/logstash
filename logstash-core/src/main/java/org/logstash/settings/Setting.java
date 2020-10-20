package org.logstash.settings;

import org.jruby.anno.JRubyMethod;

import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.function.Predicate;

public class Setting {

    private final String name;
    final Class<? extends Object> klass;
    protected Object defaultValue;
    private boolean valueIsSet;
    private Object value;
    private final boolean strict;
    private final Predicate<Object> validator;

    Setting(String name, Class<? extends Object> klass, Object defaultValue, boolean strict) {
        this(name, klass, defaultValue, strict, null);
    }

    Setting(String name, Class<? extends Object> klass, Object defaultValue, boolean strict, Predicate<Object> validator) {
        this.name = name;
        this.klass = klass;
        this.strict = strict;
        this.validator = validator;
        this.value = null;
        this.valueIsSet = false;
        this.defaultValue = defaultValue;
    }

    void init() {
        if (strict) {
            validate(defaultValue);
        }
    }

    // Copy constructor
    Setting(Setting copy) {
        this.name = copy.name;
        this.klass = copy.klass;
        this.defaultValue = copy.defaultValue;
        this.strict = copy.strict;
        this.validator = copy.validator;
    }

    public String getName() {
        return name;
    }

    public Object getDefault() {
        return defaultValue;
    }

    public Object getValue() {
        if (valueIsSet) {
            return value;
        } else {
            return defaultValue;
        }
    }

    @JRubyMethod(name = "set?")
    public boolean isValueIsSet() {
        return valueIsSet;
    }

    public boolean isStrict() {
        return strict;
    }

    public Object set(Object value) {
        if (strict) {
            validate(value);
        }
        this.value = value;
        this.valueIsSet = true;
        return value;
    }

    /**
     * Used by Ruby subclasses to assign value without any validation
     * */
    protected void assignValue(Object value) {
        this.value = value;
        this.valueIsSet = true;
    }

    public void reset() {
        value = null;
        valueIsSet = false;
    }

    public Map<String, Object> toHash() {
        Map<String, Object> map = new HashMap<>(5);
        map.put("name", name);
        map.put("klass", klass);
        map.put("value", value);
        map.put("value_is_set", valueIsSet);
        map.put("default", defaultValue);
        return map;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Setting setting = (Setting) o;
        return valueIsSet == setting.valueIsSet &&
                name.equals(setting.name) &&
                klass.equals(setting.klass) &&
                Objects.equals(defaultValue, setting.defaultValue) &&
                Objects.equals(value, setting.value);
    }

    @Override
    public int hashCode() {
        return Objects.hash(name, klass, defaultValue, valueIsSet, value);
    }

    public void validateValue(Object value) {
        validate(value);
    }

    protected void validate(Object input) {
        if (!klass.isInstance(input)) {
            throw new IllegalArgumentException("Setting \"" + name + "\" must be a " + klass + ". Received: " + input + " (" + input.getClass() + ")");
        }
        if (validator != null && !validator.test(input)) {
            throw new IllegalArgumentException("Failed to validate setting \"" + name + "\" with value: " + input);
        }
    }

}
