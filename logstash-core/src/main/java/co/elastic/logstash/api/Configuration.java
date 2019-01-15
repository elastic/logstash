package co.elastic.logstash.api;

import java.util.Collection;

public interface Configuration {
    <T> T get(PluginConfigSpec<T> configSpec);

    Object getRawValue(PluginConfigSpec<?> configSpec);

    boolean contains(PluginConfigSpec<?> configSpec);

    Collection<String> allKeys();
}
