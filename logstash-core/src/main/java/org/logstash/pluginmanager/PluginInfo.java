package org.logstash.pluginmanager;

public class PluginInfo {
    final PluginLocation pluginLocation;
    final PluginVersion pluginVersion;

    public PluginInfo(PluginLocation pluginLocation, PluginVersion pluginVersion) {
        this.pluginLocation = pluginLocation;
        this.pluginVersion = pluginVersion;
    }
}
