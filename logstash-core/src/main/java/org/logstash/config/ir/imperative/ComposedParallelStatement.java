package org.logstash.config.ir.imperative;

import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.SourceMetadata;
import org.logstash.config.ir.graph.Graph;

import java.util.List;

/**
 * Created by andrewvc on 9/22/16.
 */
public class ComposedParallelStatement extends ComposedStatement {
    public ComposedParallelStatement(SourceMetadata meta, List<Statement> statements) throws InvalidIRException {
        super(meta, statements);
    }

    @Override
    protected String composeTypeString() {
        return "composed-parallel";
    }

    @Override
    public Graph toGraph() throws InvalidIRException {
        Graph g = Graph.empty();

        for (Statement s : getStatements()) {
            g = Graph.combine(g, s.toGraph()).graph;
        }

        return g;
    }
}
