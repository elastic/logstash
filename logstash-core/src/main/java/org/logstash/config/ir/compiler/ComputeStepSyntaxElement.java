package org.logstash.config.ir.compiler;

import java.io.IOException;
import java.io.StringReader;
import java.lang.reflect.InvocationTargetException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;
import org.codehaus.commons.compiler.CompileException;
import org.codehaus.janino.ClassBodyEvaluator;

/**
 * One step a compiled pipeline. In the current implementation each step compiles to a
 * {@link Dataset}.
 */
final class ComputeStepSyntaxElement implements SyntaxElement {

    private static final DynamicClassLoader CLASS_LOADER = new DynamicClassLoader();

    /**
     * Cache of runtime compiled classes to prevent duplicate classes being compiled.
     */
    private static final Map<ComputeStepSyntaxElement, Class<? extends Dataset>> CLASS_CACHE
        = new HashMap<>();

    /**
     * Sequence number to ensure unique naming for runtime compiled classes.
     */
    private static final AtomicInteger SEQUENCE = new AtomicInteger(0);

    private final String name;

    private final Iterable<MethodSyntaxElement> methods;

    private final ClassFields fields;

    ComputeStepSyntaxElement(final Iterable<MethodSyntaxElement> methods,
        final ClassFields fields) {
        this(String.format("CompiledDataset%d", SEQUENCE.incrementAndGet()), methods, fields);
    }

    private ComputeStepSyntaxElement(final String name, final Iterable<MethodSyntaxElement> methods,
        final ClassFields fields) {
        this.name = name;
        this.methods = methods;
        this.fields = fields;
    }

    public <T extends Dataset> T instantiate(final Class<T> interfce) {
        try {
            final Class<? extends Dataset> clazz;
            if (CLASS_CACHE.containsKey(this)) {
                clazz = CLASS_CACHE.get(this);
            } else {
                final ClassBodyEvaluator se = new ClassBodyEvaluator();
                se.setParentClassLoader(CLASS_LOADER);
                se.setImplementedInterfaces(new Class[]{interfce});
                se.setClassName(name);
                se.cook(new StringReader(generateCode()));
                clazz = (Class<T>) se.getClazz();
                CLASS_LOADER.addClass(clazz);
                CLASS_CACHE.put(this, clazz);
            }
            return (T) clazz.<T>getConstructor(ctorTypes()).newInstance(ctorArguments());
        } catch (final CompileException | IOException | NoSuchMethodException
            | InvocationTargetException | InstantiationException | IllegalAccessException ex) {
            throw new IllegalStateException(ex);
        }
    }

    /**
     * @return Array of constructor argument types with the same ordering that is used by
     * {@link #ctorArguments()}.
     */
    private Class<?>[] ctorTypes() {
        return fields.ctorAssigned().getFields().stream()
            .map(FieldDefinition::asVariable)
            .map(typedVar -> typedVar.type).toArray(Class<?>[]::new);
    }

    /**
     * @return Array of constructor arguments
     */
    private Object[] ctorArguments() {
        return fields.ctorAssigned().getFields().stream()
            .map(FieldDefinition::getCtorArgument).toArray();
    }

    @Override
    public String generateCode() {
        return SyntaxFactory.join(
            combine(
                StreamSupport.stream(methods.spliterator(), false)
                    .toArray(SyntaxElement[]::new)
            ), fields.inlineAssigned().generateCode(), fieldsAndCtor()
        );
    }

    @Override
    public int hashCode() {
        return normalizedSource().hashCode();
    }

    @Override
    public boolean equals(final Object other) {
        return other instanceof ComputeStepSyntaxElement &&
            normalizedSource().equals(((ComputeStepSyntaxElement) other).normalizedSource());
    }

    /**
     * Normalizes away the name of the class so that two classes of different name but otherwise
     * equivalent syntax get correctly compared by {@link #equals(Object)}.
     * @return Source of this class, with its name set to {@code CONSTANT}.
     */
    private String normalizedSource() {
        return new ComputeStepSyntaxElement("CONSTANT", methods, fields)
            .generateCode();
    }

    /**
     * Generates the Java code for defining one field and constructor argument for each given value.
     * constructor for
     * @return Java Source String
     */
    private String fieldsAndCtor() {
        final Closure constructor = new Closure();
        final FieldDeclarationGroup ctorFields = fields.ctorAssigned();
        final Collection<VariableDefinition> ctor = new ArrayList<>();
        for (final FieldDefinition field : ctorFields.getFields()) {
            if (field.getCtorArgument() != null) {
                final String fieldName = field.getName();
                final VariableDefinition fieldVar = field.asVariable();
                final VariableDefinition argVar =
                    fieldVar.rename(SyntaxFactory.join(fieldName, "argument"));
                constructor.add(SyntaxFactory.assignment(fieldVar.access(), argVar.access()));
                ctor.add(argVar);
            }
        }
        return combine(ctorFields, MethodSyntaxElement.constructor(name, constructor, ctor));
    }

    /**
     * Renders the string concatenation of the given {@link SyntaxElement}, delimited by
     * line breaks.
     * @param parts Elements to concatenate
     * @return Java source
     */
    private static String combine(final SyntaxElement... parts) {
        return Arrays.stream(parts).map(SyntaxElement::generateCode)
            .collect(Collectors.joining("\n"));
    }

}
