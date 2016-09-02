package org.logstash.config.ir.imperative;

import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.SourceMetadata;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.PluginVertex;
import org.logstash.config.ir.graph.Vertex;

import java.util.Map;

/**
 * Created by andrewvc on 9/6/16.
 */
public class PluginStatement extends Statement {
    private final Map<String, Object> pluginArguments;
    private final String pluginName;

    public String getPluginName() {
        return pluginName;
    }

    public Map<String, Object> getPluginArguments() {
        return pluginArguments;
    }

    public PluginStatement(SourceMetadata meta, String pluginName, Map<String, Object> pluginArguments) {
        super(meta);
        this.pluginName = pluginName;
        this.pluginArguments = pluginArguments;
    }

    @Override
    public boolean sourceComponentEquals(SourceComponent sourceComponent) {
        if (sourceComponent == null) return false;
        if (sourceComponent == this) return true;
        if (sourceComponent instanceof PluginStatement) {
            PluginStatement other = (PluginStatement) sourceComponent;
            return (this.pluginName.equals(other.pluginName) && this.pluginArguments.equals(other.getPluginArguments()));
        }
        return false;
    }

    @Override
    public String toString(int indent) {
        return indentPadding(indent) + "(plugin '" + pluginName + "' " + getPluginArguments().toString() + ")";
    }

    @Override
    public Graph toGraph() {
        Vertex pluginVertex = new PluginVertex(getMeta(), pluginName, pluginArguments);
        return Graph.empty().addVertex(pluginVertex);
    }
}
