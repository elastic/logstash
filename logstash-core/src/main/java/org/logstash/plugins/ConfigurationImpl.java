package org.logstash.plugins;

import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.PluginConfigSpec;
import co.elastic.logstash.api.Codec;
import org.logstash.config.ir.compiler.RubyIntegration;

import java.util.Collection;
import java.util.Map;

/**
 * Configuration for Logstash Java plugins.
 */
public final class ConfigurationImpl implements Configuration {

    private final RubyIntegration.PluginFactory pluginFactory;
    private final Map<String, Object> rawSettings;

    /**
     * @param raw           Configuration settings map. Values are serialized.
     * @param pluginFactory Plugin factory for resolving default codecs by name.
     */
    public ConfigurationImpl(final Map<String, Object> raw, RubyIntegration.PluginFactory pluginFactory) {
        this.pluginFactory = pluginFactory;
        this.rawSettings = raw;
    }

    /**
     * @param raw Configuration Settings Map. Values are serialized.
     */
    public ConfigurationImpl(final Map<String, Object> raw) {
        this(raw, null);
    }

    @Override
    @SuppressWarnings("unchecked")
    public <T> T get(final PluginConfigSpec<T> configSpec) {
        if (rawSettings.containsKey(configSpec.name())) {
            Object o = rawSettings.get(configSpec.name());
            if (configSpec.type().isAssignableFrom(o.getClass())) {
                return (T) o;
            } else {
                throw new IllegalStateException(
                        String.format("Setting value for '%s' of type '%s' incompatible with defined type of '%s'",
                                configSpec.name(), o.getClass(), configSpec.type()));
            }
        } else if (configSpec.type() == Codec.class && configSpec.getRawDefaultValue() != null && pluginFactory != null) {
            Codec codec = pluginFactory.buildDefaultCodec(configSpec.getRawDefaultValue());
            return configSpec.type().cast(codec);
        } else {
            return configSpec.defaultValue();
        }
    }

    @Override
    public Object getRawValue(final PluginConfigSpec<?> configSpec) {
        return rawSettings.get(configSpec.name());
    }

    @Override
    public boolean contains(final PluginConfigSpec<?> configSpec) {
        return rawSettings.containsKey(configSpec.name());
    }

    @Override
    public Collection<String> allKeys() {
        return rawSettings.keySet();
    }

}
