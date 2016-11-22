package org.logstash.config.ir.graph;

import org.logstash.config.ir.ISourceComponent;
import org.logstash.config.ir.PluginDefinition;
import org.logstash.config.ir.SourceMetadata;

import java.util.Map;
import java.util.Objects;
import java.util.UUID;

/**
 * Created by andrewvc on 9/15/16.
 */
public class PluginVertex extends Vertex {
    private final SourceMetadata meta;

    public String getId() {
        return id;
    }

    @Override
    public SourceMetadata getMeta() {
        return meta;
    }

    private final String id;

    public PluginDefinition getPluginDefinition() {
        return pluginDefinition;
    }

    private final PluginDefinition pluginDefinition;

    public PluginVertex(SourceMetadata meta, PluginDefinition pluginDefinition) {
        super(meta);
        this.meta = meta;

        this.pluginDefinition = pluginDefinition;

        Object argId = this.pluginDefinition.getArguments().get("id");
        this.id = argId != null ? argId.toString() : UUID.randomUUID().toString();
        this.pluginDefinition.getArguments().put("id", this.id);
    }

    public String toString() {
        return "P[" + pluginDefinition + "]";
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
