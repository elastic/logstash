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
            new VariableDefinition(value.getClass(), field(index)), false,
            null, value
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
            new VariableDefinition(type, field(index)), true, null, null
        );
    }

    /**
     * Creates an immutable field that is assigned its value inline in the class body by the given
     * syntax element.
     * @param index Index for naming
     * @param type Type of the field
     * @param initializer Initializer syntax
     * @return Field definition
     */
    public static FieldDefinition withInitializer(final int index, final Class<?> type,
        final SyntaxElement initializer) {
        return new FieldDefinition(
            new VariableDefinition(type, field(index)), false, initializer, null
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

    /**
     * Field Naming Schema.
     * @param id Index for naming
     * @return Field name
     */
    private static String field(final int id) {
        return String.format("field%d", id);
    }
}
