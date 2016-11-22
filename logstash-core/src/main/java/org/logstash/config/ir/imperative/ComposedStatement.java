package org.logstash.config.ir.imperative;

import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.SourceMetadata;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Created by andrewvc on 9/6/16.
 */
public abstract class ComposedStatement extends Statement {
    public interface IFactory {
        ComposedStatement make(SourceMetadata meta, List<Statement> statements) throws InvalidIRException;
    }

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
        if (sourceComponent.getClass().equals(this.getClass())) {
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
        return "(" + this.composeTypeString() + "\n" +
                getStatements().stream().
                  map(s -> s.toString(indent+2)).
                  collect(Collectors.joining("\n")) +
                "\n";
    }

    protected abstract String composeTypeString();
}
