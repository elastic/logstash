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
import java.util.Collection;
import java.util.stream.Collectors;

/**
 * All fields in a Java class. Manages correctly naming and typing fields to avoid collisions and
 * manual naming in generated code.
 */
final class ClassFields {

    private final Collection<FieldDefinition> definitions = new ArrayList<>();

    private final Collection<Closure> afterInit = new ArrayList<>();

    /**
     * Adds a field holding the given {@link Object}.
     * @param obj Object to add field for
     * @return The field's syntax element that can be used in method bodies
     */
    public ValueSyntaxElement add(final Object obj) {
        return addField(FieldDefinition.fromValue(definitions.size(), obj));
    }

    /**
     * Adds a mutable field of the given type, that doesn't have a default value and is not
     * initialized by a constructor assignment.
     * Renders as e.g. {@code private boolean field7}
     * @param type Type of the mutable field.
     * @return The field's syntax element that can be used in method bodies
     */
    public ValueSyntaxElement add(final Class<?> type) {
        return addField(FieldDefinition.mutableUnassigned(definitions.size(), type));
    }

    /**
     * Add a {@link Closure} that should be executed in the constructor after field assignments
     * have been executed.
     * @param closure Closure to run after field assignments
     */
    public void addAfterInit(final Closure closure) {
        afterInit.add(closure);
    }

    /**
     * Returns a closure of actions that should be run in the constructor after all field
     * assignments have been executed.
     * @return Closure that should be executed after field assignments are done
     */
    public Closure afterInit() {
        return Closure.wrap(afterInit.toArray(new Closure[0]));
    }

    /**
     * Returns the subset of fields that are assigned in the constructor.
     * @return Subset of fields to be assigned by the constructor
     */
    public FieldDeclarationGroup ctorAssigned() {
        return new FieldDeclarationGroup(
            definitions.stream().filter(field -> field.getCtorArgument() != null)
                .collect(Collectors.toList())
        );
    }

    /**
     * Returns the subset of fields that are not assigned in the constructor.
     * They are either mutable without a default value or assigned inline in the class body.
     * @return Subset of fields not assigned by the constructor
     */
    public FieldDeclarationGroup inlineAssigned() {
        return new FieldDeclarationGroup(
            definitions.stream().filter(field -> field.getCtorArgument() == null)
                .collect(Collectors.toList())
        );
    }

    private ValueSyntaxElement addField(final FieldDefinition field) {
        this.definitions.add(field);
        return field.asVariable().access();
    }
}
