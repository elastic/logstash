package org.logstash.config.ir.compiler;

import java.util.ArrayList;
import java.util.Collection;
import java.util.stream.Collectors;

/**
 * All fields in a Java class. Manages correctly naming and typing fields to avoid collisions and
 * manual naming in generated code.
 */
final class ClassFields {

    private final Collection<FieldDefinition> definitions;

    ClassFields() {
        definitions = new ArrayList<>();
    }

    /**
     * Add a field of given type that is initialized by the given {@link SyntaxElement} that will
     * be executed in the class body.
     * Renders as e.g. {@code private final Ruby field5 = RubyUtil.RUBY}.
     * @param type Type of the field
     * @param initializer Syntax to initialize it in-line.
     * @return The field's syntax element that can be used in method bodies
     */
    public ValueSyntaxElement add(final Class<?> type, final SyntaxElement initializer) {
        return addField(FieldDefinition.withInitializer(definitions.size(), type, initializer));
    }

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
