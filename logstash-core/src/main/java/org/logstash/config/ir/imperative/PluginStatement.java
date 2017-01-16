package org.logstash.config.ir.imperative;

import org.logstash.config.ir.ISourceComponent;
import org.logstash.config.ir.PluginDefinition;
import org.logstash.config.ir.SourceMetadata;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.PluginVertex;
import org.logstash.config.ir.graph.Vertex;

import java.util.Map;

/**
 * Created by andrewvc on 9/6/16.
 */
public class PluginStatement extends Statement {
    private final PluginDefinition pluginDefinition;

    public PluginStatement(SourceMetadata meta, PluginDefinition pluginDefinition) {
        super(meta);
        this.pluginDefinition = pluginDefinition;
    }

    @Override
    public boolean sourceComponentEquals(ISourceComponent sourceComponent) {
        if (sourceComponent == null) return false;
        if (sourceComponent == this) return true;
        if (sourceComponent instanceof PluginStatement) {
            PluginStatement other = (PluginStatement) sourceComponent;
            return this.pluginDefinition.equals(other.pluginDefinition);
        }
        return false;
    }

    @Override
    public String toString(int indent) {
        return indentPadding(indent) + this.pluginDefinition;
    }

    @Override
    public Graph toGraph() {
        Vertex pluginVertex = new PluginVertex(getMeta(), pluginDefinition);
        return Graph.empty().addVertex(pluginVertex);
    }
}
