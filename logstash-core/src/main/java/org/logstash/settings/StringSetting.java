package org.logstash.settings;

import java.util.List;

public final class StringSetting extends Setting<String> {

    public StringSetting(String value, SettingSpecification<String> settingOption) {
        super(value, settingOption);
    }

    public static SettingSpecification<String> spec(String name, String defaultValue, List<String> possibleStrings) {
        return new SettingSpecification<>(name, defaultValue, value -> possibleStrings.isEmpty() || possibleStrings.contains(value));
    }
}
