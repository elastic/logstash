package org.logstash.config.ir.graph;

import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.PluginDefinition;
import org.logstash.config.ir.SourceComponent;

public class PluginVertex extends Vertex {
    private final PluginDefinition pluginDefinition;
    private final String sourceFile;
    private final int sourceLine;

    public PluginDefinition getPluginDefinition() {
        return pluginDefinition;
    }

    public PluginVertex(SourceWithMetadata meta, PluginDefinition pluginDefinition) {
        this(meta, pluginDefinition, null, -1);
    }

    public PluginVertex(SourceWithMetadata meta, PluginDefinition pluginDefinition, String sourceFile, int sourceLine) {
        // We know that if the ID value exists it will be as a string
        super(meta, (String) pluginDefinition.getArguments().get("id"));
        this.pluginDefinition = pluginDefinition;
        this.sourceFile = sourceFile;
        this.sourceLine = sourceLine;
    }

    public String toString() {
        return "P[" + pluginDefinition + "|" + this.getSourceWithMetadata() + "]";
    }

    @Override
    public PluginVertex copy() {
        return new PluginVertex(this.getSourceWithMetadata(), pluginDefinition, sourceFile, sourceLine);
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

    public String getSourceFile() {
        return sourceFile;
    }

    public int getSourceLine() {
        return sourceLine;
    }
}
