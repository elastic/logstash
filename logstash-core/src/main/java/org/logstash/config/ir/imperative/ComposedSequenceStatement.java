package org.logstash.config.ir.imperative;

import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.SourceMetadata;
import org.logstash.config.ir.graph.Graph;

import java.util.List;

/**
 * Created by andrewvc on 9/22/16.
 */
public class ComposedSequenceStatement extends ComposedStatement {
    public ComposedSequenceStatement(SourceMetadata meta, List<Statement> statements) throws InvalidIRException {
        super(meta, statements);
    }

    @Override
    protected String composeTypeString() {
        return "do-sequence";
    }

    @Override
    public Graph toGraph() throws InvalidIRException {
        Graph g = Graph.empty();

        for (Statement statement : getStatements()) {
            Graph sg = statement.toGraph();
            g.threadLeavesInto(sg);
        }

        return g;
    }
}
