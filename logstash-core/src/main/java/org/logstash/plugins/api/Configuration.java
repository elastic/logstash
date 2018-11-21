package org.logstash.plugins.api;

import java.nio.file.Path;
import java.util.Collection;
import java.util.Map;

/**
 * LS Configuration example. Should be implemented like Spark config or Hadoop job config classes.
 */
public final class Configuration {

    private final Map<String, String> rawSettings;

    /**
     * @param raw Configuration Settings Map. Values are serialized.
     */
    public Configuration(final Map<String, String> raw) {
        this.rawSettings = raw;
    }

    public <T> T get(final PluginConfigSpec<T> configSpec) {
        // TODO: Implement
        return null;
    }

    public String getRawValue(PluginConfigSpec<?> configSpec) {
        String rawValue = rawSettings.get(configSpec.name());
        return rawValue == null ? (String)configSpec.defaultValue() : rawValue;
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
            name, String.class, null, false, false
        );
    }

    public static PluginConfigSpec<String> stringSetting(final String name, final String defaultValue) {
        return new PluginConfigSpec<>(
                name, String.class, defaultValue, false, false
        );
    }

    public static PluginConfigSpec<String> requiredStringSetting(final String name) {
        return new PluginConfigSpec<>(name, String.class, null, false, true);
    }

    public static PluginConfigSpec<Long> numSetting(final String name) {
        return new PluginConfigSpec<>(
            name, Long.class, null, false, false
        );
    }

    public static PluginConfigSpec<Long> numSetting(final String name, final long defaultValue) {
        return new PluginConfigSpec<>(
            name, Long.class, defaultValue, false, false
        );
    }

    public static PluginConfigSpec<Path> pathSetting(final String name) {
        return new PluginConfigSpec<>(name, Path.class, null, false, false);
    }

    public static PluginConfigSpec<Boolean> booleanSetting(final String name) {
        return new PluginConfigSpec<>(name, Boolean.class, null, false, false);
    }

    @SuppressWarnings("unchecked")
    public static PluginConfigSpec<Map<String, String>> hashSetting(final String name) {
        return new PluginConfigSpec(name, Map.class, null, false, false);
    }

    @SuppressWarnings("unchecked")
    public static <T> PluginConfigSpec<Map<String, T>> requiredFlatHashSetting(
        final String name, Class<T> type) {
        //TODO: enforce subtype
        return new PluginConfigSpec(
            name, Map.class, null, false, true
        );
    }

    @SuppressWarnings("unchecked")
    public static PluginConfigSpec<Map<String, Configuration>> requiredNestedHashSetting(
        final String name, final Collection<PluginConfigSpec<?>> spec) {
        return new PluginConfigSpec(
            name, Map.class, null, false, true, spec
        );
    }
}
