package co.elastic.logstash.api;

import java.nio.file.Path;
import java.util.Collection;
import java.util.Map;

/**
 * Configuration for Logstash Java plugins.
 */
public final class Configuration {

    private final Map<String, Object> rawSettings;

    /**
     * @param raw Configuration Settings Map. Values are serialized.
     */
    public Configuration(final Map<String, Object> raw) {
        this.rawSettings = raw;
    }

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
        } else {
            return configSpec.defaultValue();
        }
    }

    public Object getRawValue(final PluginConfigSpec<?> configSpec) {
        return rawSettings.get(configSpec.name());
    }

    public boolean contains(final PluginConfigSpec<?> configSpec) {
        return rawSettings.containsKey(configSpec.name());
    }

    public Collection<String> allKeys() {
        return rawSettings.keySet();
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

    @SuppressWarnings({"unchecked","rawtypes"})
    public static PluginConfigSpec<Map<String, String>> hashSetting(final String name) {
        return new PluginConfigSpec(name, Map.class, null, false, false);
    }

    @SuppressWarnings({"unchecked","rawtypes"})
    public static <T> PluginConfigSpec<Map<String, T>> requiredFlatHashSetting(
        final String name, Class<T> type) {
        //TODO: enforce subtype
        return new PluginConfigSpec(
            name, Map.class, null, false, true
        );
    }

    @SuppressWarnings({"unchecked","rawtypes"})
    public static PluginConfigSpec<Map<String, Configuration>> requiredNestedHashSetting(
        final String name, final Collection<PluginConfigSpec<?>> spec) {
        return new PluginConfigSpec(
            name, Map.class, null, false, true, spec
        );
    }
}
