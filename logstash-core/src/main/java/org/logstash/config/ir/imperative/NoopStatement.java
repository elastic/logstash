package org.logstash.config.ir.imperative;

import org.logstash.config.ir.SourceComponent;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.graph.Graph;

public class NoopStatement extends Statement {

    public NoopStatement(SourceWithMetadata meta) {
        super(meta);
    }

    @Override
    public boolean sourceComponentEquals(SourceComponent sourceComponent) {
        if (sourceComponent == null) return false;
        if (sourceComponent instanceof NoopStatement) return true;
        return false;
    }

    @Override
    public String toString(int indent) {
        return indentPadding(indent) + "(Noop)";
    }

    @Override
    public Graph toGraph() {
        return Graph.empty();
    }

}
