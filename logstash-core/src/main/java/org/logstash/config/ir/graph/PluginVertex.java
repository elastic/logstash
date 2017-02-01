package org.logstash.config.ir.graph;

import org.logstash.common.Util;
import org.logstash.config.ir.ISourceComponent;
import org.logstash.config.ir.PluginDefinition;
import org.logstash.config.ir.SourceMetadata;

/**
 * Created by andrewvc on 9/15/16.
 */
public class PluginVertex extends Vertex {
    private final SourceMetadata meta;
    private final String id;
    private final PluginDefinition pluginDefinition;

    public String getId() {
        if (id != null) return id;
        if (this.getGraph() == null) {
            throw new RuntimeException("Attempted to get ID from PluginVertex before attaching it to a graph!");
        }
        return this.uniqueHash();
    }

    public PluginDefinition getPluginDefinition() {
        return pluginDefinition;
    }
    @Override
    public SourceMetadata getMeta() {
        return meta;
    }


    public PluginVertex(SourceMetadata meta, PluginDefinition pluginDefinition) {
        super(meta);
        this.meta = meta;

        this.pluginDefinition = pluginDefinition;

        Object argId = this.pluginDefinition.getArguments().get("id");
        this.id = argId != null ? argId.toString() : null;
    }

    public String toString() {
        return "P[" + pluginDefinition + "|" + this.getMeta() + "]";
    }

    @Override
    public String individualHashSource() {
        return Util.sha256(this.getClass().getCanonicalName() + "|" +
                (this.id != null ? this.id : "NOID") + "|" +
                //this.getMeta().getSourceLine() + "|" + this.getMeta().getSourceColumn() + "|" + // Temp hack REMOVE BEFORE RELEASE
                this.getPluginDefinition().hashSource());
    }

    public String individualHash() {
        return Util.sha256(individualHashSource());
    }

    @Override
    public PluginVertex copy() {
        return new PluginVertex(meta, getPluginDefinition());
    }

    @Override
    public boolean sourceComponentEquals(ISourceComponent other) {
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
