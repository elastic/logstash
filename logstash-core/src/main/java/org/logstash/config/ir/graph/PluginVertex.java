package org.logstash.config.ir.graph;

import org.logstash.config.ir.SourceMetadata;

import java.util.Map;

/**
 * Created by andrewvc on 9/15/16.
 */
public class PluginVertex extends Vertex {
    private final Map<String, Object> pluginArguments;
    private final String pluginName;
    private final SourceMetadata meta;

    public PluginVertex(SourceMetadata meta, String pluginName, Map<String, Object> pluginArguments) {
        this.meta = meta;
        this.pluginName = pluginName;
        this.pluginArguments = pluginArguments;
    }

    public String toString() {
        return "P[" + pluginName + " " + pluginArguments + "]";
    }
}
