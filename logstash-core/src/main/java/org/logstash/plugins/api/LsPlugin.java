package org.logstash.plugins.api;

import java.util.Collection;

public interface LsPlugin {

    Collection<PluginConfigSpec<?>> configSchema();
}
