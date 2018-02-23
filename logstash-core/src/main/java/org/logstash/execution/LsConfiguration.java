package org.logstash.execution;

import java.nio.file.Path;
import java.util.Collection;
import java.util.Map;

/**
 * LS Configuration example. Should be implemented like Spark config or Hadoop job config classes.
 */
public final class LsConfiguration {

    /**
     * @param raw Configuration Settings Map. Values are serialized.
     */
    public LsConfiguration(final Map<String, String> raw) {

    }

    public <T> T get(final PluginConfigSpec<T> configSpec) {
        // TODO: Implement
        return null;
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
    public static PluginConfigSpec<Map<String, String>> requiredHashSetting(final String name) {
        return new PluginConfigSpec(name, Map.class, null, false, true);
    }
}
