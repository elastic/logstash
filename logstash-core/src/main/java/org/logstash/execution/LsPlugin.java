package org.logstash.execution;

import java.util.Collection;

public interface LsPlugin {

    Collection<PluginConfigSpec<?>> configSchema();
}
