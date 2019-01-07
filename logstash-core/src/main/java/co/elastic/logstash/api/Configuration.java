package co.elastic.logstash.api;

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

}
