package org.logstash.settings;

import java.util.function.Predicate;

public final class SettingPort extends SettingInteger {

    public static final Predicate<Integer> VALID_PORT_RANGE = new Predicate<>() {
        @Override
        public boolean test(Integer integer) {
            return isValid(integer);
        }
    };

    public SettingPort(String name, Integer defaultValue) {
        super(name, defaultValue);
    }

    public SettingPort(String name, Integer defaultValue, boolean strict) {
        this(name, defaultValue, strict, VALID_PORT_RANGE);
    }

    protected SettingPort(String name, Integer defaultValue, boolean strict, Predicate<Integer> validator) {
        super(name, defaultValue, strict, validator);
    }

    public static boolean isValid(int port) {
        return 1 <= port && port <= 65535;
    }

}
