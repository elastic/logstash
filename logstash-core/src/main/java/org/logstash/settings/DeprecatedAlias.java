package org.logstash.settings;

import co.elastic.logstash.api.DeprecationLogger;
import org.apache.logging.log4j.LogManager;
import org.logstash.log.DefaultDeprecationLogger;

import java.util.function.Predicate;

/**
 * A <code>DeprecatedAlias</code> provides a deprecated alias for a setting, and is meant
 * to be used exclusively through @see org.logstash.settings.SettingWithDeprecatedAlias#wrap()
 * */
final class DeprecatedAlias<T> extends SettingDelegator<T> {
    private final DeprecationLogger deprecationLogger = new DefaultDeprecationLogger(LogManager.getLogger(DeprecatedAlias.class));

    private SettingWithDeprecatedAlias<T> canonicalProxy;

    protected DeprecatedAlias(String name, T defaultValue, boolean strict, Predicate<T> validator) {
        super(name, defaultValue, strict, validator);
    }

    DeprecatedAlias(SettingWithDeprecatedAlias<T> canonicalProxy, String aliasName) {
        super(canonicalProxy.getCanonicalSetting().clone().deprecate(aliasName));
        this.canonicalProxy = canonicalProxy;
    }

    @Override
    public void set(T newValue) {
        deprecationLogger.deprecated("logstash.settings.deprecation.set deprecated_alias {} canonical_name: {}", getName(), canonicalProxy.getName());
        super.set(newValue);
    }

    @Override
    public T value() {
        deprecationLogger.deprecated("logstash.settings.deprecation.queried deprecated_alias {} canonical_name: {}", getName(), canonicalProxy.getName());
        return super.value();
    }

    @Override
    public void validateValue() {
        // bypass deprecation warning
        if (isSet()) {
            getDelegate().validateValue();
        }
    }
}
