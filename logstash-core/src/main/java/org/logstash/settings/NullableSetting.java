package org.logstash.settings;

public class NullableSetting<T> extends SettingDelegator<T> {

    NullableSetting(Setting<T> delegate) {
        super(delegate);
    }

    @Override
    protected void validate(T input) throws IllegalArgumentException {
        if (input == null) {
            return;
        }
        getDelegate().validate(input);
    }

    // prevent delegate from intercepting
    @Override
    public void validateValue() {
        validate(value());
    }
}
