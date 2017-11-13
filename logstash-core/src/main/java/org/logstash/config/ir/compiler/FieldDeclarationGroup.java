package org.logstash.config.ir.compiler;

import java.util.Collection;
import java.util.stream.Collectors;

/**
 * A group of field declarations.
 */
final class FieldDeclarationGroup implements SyntaxElement {

    private final Collection<FieldDefinition> fields;

    FieldDeclarationGroup(final Collection<FieldDefinition> defs) {
        this.fields = defs;
    }

    public Collection<FieldDefinition> getFields() {
        return fields;
    }

    @Override
    public String generateCode() {
        return fields.isEmpty() ? "" : SyntaxFactory.join(fields.stream().map(
            SyntaxElement::generateCode).collect(Collectors.joining(";\n")), ";"
        );
    }
}
