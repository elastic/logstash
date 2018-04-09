package org.logstash;

import org.logstash.LogstashAPI.AgentObserver;
import org.pf4j.DefaultPluginManager;
import org.pf4j.PluginManager;

import java.nio.file.Path;

import static org.logstash.Logstash.PLUGIN_MANAGER;

public class AgentHooks {
    public void start() {
        PLUGIN_MANAGER.loadPlugins();
        PLUGIN_MANAGER.startPlugins();

        PLUGIN_MANAGER.getExtensions(AgentObserver.class).forEach(AgentObserver::onStart);
    }

    public void shutdown() {
        PLUGIN_MANAGER.getExtensions(AgentObserver.class).forEach(AgentObserver::onShutdown);
    }
}
