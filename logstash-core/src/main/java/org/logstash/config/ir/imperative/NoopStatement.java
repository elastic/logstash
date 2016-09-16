package org.logstash.config.ir.imperative;

import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.SourceMetadata;
import org.logstash.config.ir.graph.Edge;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.Vertex;

import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;

/**
 * Created by andrewvc on 9/15/16.
 */
public class NoopStatement extends Statement {

    public NoopStatement(SourceMetadata meta) {
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
