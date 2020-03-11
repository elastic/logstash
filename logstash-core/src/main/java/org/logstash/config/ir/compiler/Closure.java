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


package org.logstash.config.ir.compiler;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

/**
 * A syntactic closure.
 */
final class Closure implements MethodLevelSyntaxElement {

    /**
     * Empty and immutable {@link Closure}.
     */
    public static final Closure EMPTY = new Closure(Collections.emptyList());

    private final List<MethodLevelSyntaxElement> statements;

    public static Closure wrap(final MethodLevelSyntaxElement... statements) {
        final Closure closure = new Closure();
        for (final MethodLevelSyntaxElement statement : statements) {
            if (statement instanceof Closure) {
                closure.add((Closure) statement);
            } else {
                closure.add(statement);
            }
        }
        return closure;
    }

    Closure() {
        this(new ArrayList<>());
    }

    private Closure(final List<MethodLevelSyntaxElement> statements) {
        this.statements = statements;
    }

    public Closure add(final Closure statement) {
        statements.addAll(statement.statements);
        return this;
    }

    public Closure add(final MethodLevelSyntaxElement statement) {
        statements.add(statement);
        return this;
    }

    public boolean empty() {
        return statements.isEmpty();
    }

    @Override
    public String generateCode() {
        return statements.isEmpty() ? "" : SyntaxFactory.join(
            statements.stream().map(MethodLevelSyntaxElement::generateCode).collect(
                Collectors.joining(";\n")
            ), ";"
        );
    }
}
