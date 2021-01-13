package org.logstash.settings;

public class Setting<T> {

    private final T value;
    private final SettingSpecification<T> settingSpecification;

    public Setting(T value, SettingSpecification<T> specification) {
        this.value = value;
        this.settingSpecification = specification;

        if (settingSpecification.isStrict()) {
            settingSpecification.validate(getValue());
        }
    }

    public T getValue() {
        return value;
    }
}
