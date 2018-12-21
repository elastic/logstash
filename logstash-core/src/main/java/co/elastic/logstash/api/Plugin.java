package co.elastic.logstash.api;

import java.util.Collection;

public interface Plugin {

    Collection<PluginConfigSpec<?>> configSchema();

    String getName();

    String getId();
}
