/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.config.ir.imperative;

import org.logstash.config.ir.SourceComponent;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.common.SourceWithMetadata;

import java.util.List;
import java.util.stream.Collectors;

public abstract class ComposedStatement extends Statement {
    public interface IFactory {
        ComposedStatement make(SourceWithMetadata meta, List<Statement> statements) throws InvalidIRException;
    }

    private final List<Statement> statements;

    public ComposedStatement(SourceWithMetadata meta, List<Statement> statements) throws InvalidIRException {
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
