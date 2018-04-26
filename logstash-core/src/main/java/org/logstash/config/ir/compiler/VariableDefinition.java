package org.logstash.config.ir.compiler;

import org.jruby.internal.runtime.methods.DynamicMethod;

/**
 * Definition of a variable.
 */
final class VariableDefinition implements SyntaxElement {
    public final Class<?> type;
    public final String name;

    VariableDefinition(final Class<?> type, final SyntaxFactory.IdentifierStatement name) {
        this(type, name.generateCode());
    }

    VariableDefinition(final Class<?> type, final String name) {
        this.type = safeType(type);
        this.name = name;
    }

    /**
     * Get a {@link ValueSyntaxElement} for accessing the variable.
     * @return Syntax element allowing access to the variable
     */
    public ValueSyntaxElement access() {
        return SyntaxFactory.value(name);
    }

    /**
     * Create a copy of this instance with a new name but the same type.
     * @param newName New Name
     * @return Variable Definition with Adjusted Name
     */
    public VariableDefinition rename(final String newName) {
        return new VariableDefinition(type, newName);
    }

    @Override
    public String generateCode() {
        return SyntaxFactory.join(type.getTypeName(), " ", name);
    }

    /**
     * Determines a type that can be used in runtime compilable syntax. Types that are dynamically
     * compiled by Logstash or JRuby are filtered as their static parent types.
     * @param clazz Class to find safe type for
     * @return Safe type that can be used in syntax
     */
    private static Class<?> safeType(final Class<?> clazz) {
        final Class<?> safe;
        if (EventCondition.class.isAssignableFrom(clazz)) {
            safe = EventCondition.class;
        } else if (DynamicMethod.class.isAssignableFrom(clazz)) {
            safe = DynamicMethod.class;
        } else {
            safe = clazz;
        }
        return safe;
    }

}
