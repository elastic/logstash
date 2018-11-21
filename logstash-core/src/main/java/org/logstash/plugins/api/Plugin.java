package org.logstash.plugins.api;

import java.util.Collection;

public interface Plugin {

    Collection<PluginConfigSpec<?>> configSchema();
}
