package org.logstash.execution;

import java.util.Collection;
import org.logstash.execution.plugins.PluginConfigSpec;

public interface LsPlugin {

    Collection<PluginConfigSpec<?>> configSchema();
}
