package org.logstash.execution;

import org.logstash.execution.plugins.PluginConfigSpec;
import org.logstash.execution.plugins.StringConfigValueConverter;

import java.nio.file.Path;
import java.util.Collection;
import java.util.Map;

/**
 * LS Configuration example. Should be implemented like Spark config or Hadoop job config classes.
 */
public final class LsConfiguration {

    private Map<String, String> rawSettings;

    /**
     * @param raw Configuration Settings Map. Values are serialized.
     */
    public LsConfiguration(final Map<String, String> raw) {
        rawSettings = raw;
    }

    public <T> T get(final PluginConfigSpec<T> configSpec) {
        return configSpec.getValue(rawSettings.get(configSpec.name()));
    }

    public boolean contains(final PluginConfigSpec<?> configSpec) {
        // TODO: Implement
        return false;
    }

    public Collection<String> allKeys() {
        return null;
    }

    public static PluginConfigSpec<String> stringSetting(final String name) {
        return new PluginConfigSpec<>(
                name, String.class, null, new StringConfigValueConverter(), false, false
        );
    }

    public static PluginConfigSpec<String> stringSetting(final String name, final String def) {
        return new PluginConfigSpec<>(
                name, String.class, def, new StringConfigValueConverter(), false, false
        );
    }

    public static PluginConfigSpec<String> requiredStringSetting(final String name) {
        return new PluginConfigSpec<>(name, String.class, null, new StringConfigValueConverter(), false, true);
    }

    public static PluginConfigSpec<Long> numSetting(final String name) {
        return new PluginConfigSpec<>(
                name, Long.class, null, null, false, false
        );
    }

    public static PluginConfigSpec<Long> numSetting(final String name, final long defaultValue) {
        return new PluginConfigSpec<>(
                name, Long.class, defaultValue, null, false, false
        );
    }

    public static PluginConfigSpec<Path> pathSetting(final String name) {
        return new PluginConfigSpec<>(name, Path.class, null, null, false, false);
    }

    public static PluginConfigSpec<Boolean> booleanSetting(final String name) {
        return new PluginConfigSpec<>(name, Boolean.class, null, null, false, false);
    }

    @SuppressWarnings("unchecked")
    public static PluginConfigSpec<Map<String, String>> hashSetting(final String name) {
        return new PluginConfigSpec(name, Map.class, null, null, false, false);
    }

    @SuppressWarnings("unchecked")
    public static PluginConfigSpec<Map<String, LsConfiguration>> requiredHashSetting(
            final String name, final Collection<PluginConfigSpec<?>> spec) {
        return new PluginConfigSpec(
                name, Map.class, null, null, false, true
        );
    }
}
