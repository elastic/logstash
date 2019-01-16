package co.elastic.logstash.api;

import java.util.Collection;

/**
 * Set of configuration settings for each plugin as read from the Logstash pipeline configuration.
 */
public interface Configuration {

    /**
     * Strongly-typed accessor for a configuration setting.
     * @param configSpec The setting specification for which to retrieve the setting value.
     * @param <T>        The type of the setting value to be retrieved.
     * @return           The value of the setting for the specified setting specification.
     */
    <T> T get(PluginConfigSpec<T> configSpec);

    /**
     * Weakly-typed accessor for a configuration setting.
     * @param configSpec The setting specification for which to retrieve the setting value.
     * @return           The weakly-typed value of the setting for the specified setting specification.
     */
    Object getRawValue(PluginConfigSpec<?> configSpec);

    /**
     * @param configSpec The setting specification for which to search.
     * @return           {@code true} if a value for the specified setting specification exists in
     * this {@link Configuration}.
     */
    boolean contains(PluginConfigSpec<?> configSpec);

    /**
     * @return Collection of the names of all settings in this configuration as reported by
     * {@link PluginConfigSpec#name()}.
     */
    Collection<String> allKeys();
}
