package org.logstash.settings;

import java.util.function.Predicate;

public class SettingPositiveInteger extends SettingInteger {

    public SettingPositiveInteger(String name, Integer defaultValue) {
        super(name, defaultValue, true, new Predicate<Integer>() {
            @Override
            public boolean test(Integer v) {
                if (v <= 0) {
                    throw new IllegalArgumentException("Number must be bigger than 0. Received: " + v);
                }
                return true;
            }
        });
    }
}
