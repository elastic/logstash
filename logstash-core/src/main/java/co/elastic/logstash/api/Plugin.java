package co.elastic.logstash.api;

import java.util.Collection;

public interface Plugin {

    Collection<PluginConfigSpec<?>> configSchema();

    default String getName() {
        LogstashPlugin annotation = getClass().getDeclaredAnnotation(LogstashPlugin.class);
        return (annotation != null && !annotation.name().equals(""))
                ? annotation.name()
                : getClass().getName();
    }

    String getId();
}
