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

/**
 * Definition of an instance field, named via its numeric index according to the schema
 * {@code field$[index]}.
 */
final class FieldDefinition implements SyntaxElement {

    private final VariableDefinition def;

    private final boolean mutable;

    private final SyntaxElement initializer;

    private final Object ctorArgument;

    /**
     * Create an immutable field with given value and at given index.
     * @param index Index for naming
     * @param value Object value of the field
     * @return Field definition
     */
    public static FieldDefinition fromValue(final int index, final Object value) {
        return new FieldDefinition(
            variableDefinition(value.getClass(), index), false, null, value
        );
    }

    /**
     * Creates a mutable field with given type and without an assigned value.
     * @param index Index for naming
     * @param type Type of the field
     * @return Field definition
     */
    public static FieldDefinition mutableUnassigned(final int index, final Class<?> type) {
        return new FieldDefinition(
            variableDefinition(type, index), true, null, null
        );
    }

    private FieldDefinition(final VariableDefinition typeDef, final boolean mutable,
        final SyntaxElement initializer, final Object ctorArgument) {
        this.def = typeDef;
        this.mutable = mutable;
        this.initializer = initializer;
        this.ctorArgument = ctorArgument;
    }

    /**
     * Gets the {@link VariableDefinition} of the field.
     * @return Variable Definition
     */
    public VariableDefinition asVariable() {
        return def;
    }

    /**
     * Gets the value that is assigned to the field in the constructor if one is set
     * or {@code null} if none is set.
     * @return Constructor argument to be assigned to the field
     */
    public Object getCtorArgument() {
        return ctorArgument;
    }

    public String getName() {
        return def.name;
    }

    @Override
    public String generateCode() {
        return SyntaxFactory.join(
            "private ", mutable ? "" : "final ", def.generateCode(),
            initializer != null ? SyntaxFactory.join("=", initializer.generateCode()) : ""
        );
    }

    private static VariableDefinition variableDefinition(final Class<?> type, final int index) {
        return new VariableDefinition(type, String.format("field%d", index));
    }
}
