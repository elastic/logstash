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
    private final SourceWithMetadata meta;
    private final PluginDefinition pluginDefinition;

    public PluginDefinition getPluginDefinition() {
        return pluginDefinition;
    }
    @Override
    public SourceWithMetadata getSourceWithMetadata() {
        return meta;
    }

    public PluginVertex(SourceWithMetadata meta, PluginDefinition pluginDefinition) {
        // We know that if the ID value exists it will be as a string
        super((String) pluginDefinition.getArguments().get("id"));
        this.meta = meta;
        this.pluginDefinition = pluginDefinition;
    }

    public String toString() {
        return "P[" + pluginDefinition + "|" + this.getSourceWithMetadata() + "]";
    }

    @Override
    public String calculateIndividualHashSource() {
        try {
            return Util.digest(this.getClass().getCanonicalName() + "|" +
                    (this.getExplicitId() != null ? this.getExplicitId() : "NOID") + "|" +
                    this.pluginDefinition.getName() + "|" +
                    this.pluginDefinition.getType().toString() + "|" +
                    ObjectMappers.JSON_MAPPER
                        .writeValueAsString(this.pluginDefinition.getArguments()));
        } catch (JsonProcessingException e) {
            // This is basically impossible given the constrained values in the plugin definition
            throw new RuntimeException(e);
        }
    }

    @Override
    public PluginVertex copy() {
        return new PluginVertex(meta, pluginDefinition);
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
