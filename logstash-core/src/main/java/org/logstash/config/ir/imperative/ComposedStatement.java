package org.logstash.config.ir.imperative;

import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.SourceMetadata;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.Vertex;

import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Created by andrewvc on 9/6/16.
 */
public class ComposedStatement extends Statement {
    private final List<Statement> statements;

    public ComposedStatement(SourceMetadata meta, List<Statement> statements) throws InvalidIRException {
        super(meta);
        if (statements == null || statements.stream().anyMatch(s -> s == null)) {
            throw new InvalidIRException("Nulls eNot allowed for list eOr in statement list");
        }
        this.statements = statements;
    }

    public List<Statement> getStatements() {
        return this.statements;
    }

    public int size() {
        return getStatements().size();
    }

    @Override
    public boolean sourceComponentEquals(SourceComponent sourceComponent) {
        if (sourceComponent == null) return false;
        if (this == sourceComponent) return true;
        if (sourceComponent instanceof ComposedStatement) {
            ComposedStatement other = (ComposedStatement) sourceComponent;
            if (this.size() != other.size()) {
                return false;
            }
            for (int i = 0; i < size(); i++) {
                Statement s = this.getStatements().get(i);
                Statement os = other.getStatements().get(i);
                if (!(s.sourceComponentEquals(os))) return false;
            }
            return true;
        }
        return false;
    }

    @Override
    public String toString(int indent) {
        return indentPadding(indent) + "(compose \n" +
                statements.stream().map(s -> s.toString(indent+2)).collect(Collectors.joining("\n")) +
                "\n)";
    }

    @Override
    public Graph toGraph() throws InvalidIRException {
        Graph g = Graph.empty();


        Collection<Vertex> previousLeaves = null;
        for (Statement statement : statements) {
            Graph sg = statement.toGraph();
            Vertex root = sg.root().get();

            if (previousLeaves != null) {
                for (Vertex previousLeaf : previousLeaves) {
                    g.addByThreading(previousLeaf, root);
                }
            }

            previousLeaves = sg.leaves().collect(Collectors.toSet());
        }

        g.refresh();
        return g;
    }
}
