package org.logstash.settings;

public class BooleanSetting extends Setting<Boolean> {

    public BooleanSetting(String name, boolean defaultValue) {
        super(name, defaultValue, true, noValidator());
    }

//    protected BooleanSetting(String name, Boolean defaultValue, boolean strict, Predicate<Boolean> validator) {
//        super(name, defaultValue, strict, validator);
//    }
}