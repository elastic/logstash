package org.logstash.config.ir.graph;

import com.fasterxml.jackson.core.JsonProcessingException;
import org.logstash.ObjectMappers;
import org.logstash.common.SourceWithMetadata;
import org.logstash.common.Util;
import org.logstash.config.ir.PluginDefinition;
import org.logstash.config.ir.SourceComponent;

/**
 * Created by andrewvc on 9/15/16.
 */
public class PluginVertex extends Vertex {
    private final PluginDefinition pluginDefinition;

    public PluginDefinition getPluginDefinition() {
        return pluginDefinition;
    }


    public PluginVertex(SourceWithMetadata meta, PluginDefinition pluginDefinition) {
        // We know that if the ID value exists it will be as a string
        super(meta, (String) pluginDefinition.getArguments().get("id"));
        this.pluginDefinition = pluginDefinition;
    }

    public String toString() {
        return "P[" + pluginDefinition + "|" + this.getSourceWithMetadata() + "]";
    }

    @Override
    public PluginVertex copy() {
        return new PluginVertex(this.getSourceWithMetadata(), pluginDefinition);
    }

    @Override
    public boolean sourceComponentEquals(SourceComponent other) {
        if (other == null) return false;
        if (other == this) return true;
        if (other instanceof PluginVertex) {
            PluginVertex otherV = (PluginVertex) other;
            // We don't test ID equality because we're testing
            // Semantics, and ids have nothing to do with that
            return otherV.getPluginDefinition().sourceComponentEquals(this.getPluginDefinition());
        }
        return false;
    }
}
