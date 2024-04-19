package co.elastic.logstash.api;

import java.util.Collection;
import java.util.Collections;

public class ConfigData<T> {

    public final String name;
    public final Class<T> type;
    public final T defaultValue;
    public final boolean deprecated;
    public final boolean required;
    public final Collection<PluginConfigSpec<?>> children;

    public ConfigData(String name, Class<T> type, T defaultValue, boolean deprecated, boolean required) {
        this(name, type, defaultValue, deprecated, required, Collections.emptyList());
    }

    public ConfigData(String name, Class<T> type, T defaultValue, boolean deprecated, boolean required, Collection<PluginConfigSpec<?>> children) {
        this.name = name;
        this.type = type;
        this.defaultValue = defaultValue;
        this.deprecated = deprecated;
        this.required = required;
        this.children = children;
    }

}
