package org.logstash.config.ir.compiler;

import java.io.IOException;
import java.io.StringReader;
import java.lang.reflect.InvocationTargetException;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;
import org.codehaus.commons.compiler.CompileException;
import org.codehaus.janino.ClassBodyEvaluator;
import org.jruby.RubyArray;
import org.jruby.internal.runtime.methods.DynamicMethod;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;

/**
 * Compiler that can compile implementations of {@link Dataset} at runtime.
 */
public final class DatasetCompiler {

    /**
     * Sequence number to ensure unique naming for runtime compiled classes.
     */
    private static final AtomicInteger SEQUENCE = new AtomicInteger(0);

    /**
     * Cache of runtime compiled classes to prevent duplicate classes being compiled.
     */
    private static final Map<String, Class<?>> CLASS_CACHE = new HashMap<>();

    private static final String RETURN_NULL = "return null;";
    /**
     * Trivial {@link Dataset} that simply returns an empty collection of elements.
     */
    private static final Dataset EMPTY_DATASET =
        DatasetCompiler.compile("return Collections.EMPTY_LIST;", "");

    private DatasetCompiler() {
        // Utility Class
    }

    /**
     * Compiles and subsequently instantiates a {@link Dataset} from given code snippets and
     * constructor arguments.
     * This method must be {@code synchronized} to avoid compiling duplicate classes.
     * @param compute Method body of {@link Dataset#compute(RubyArray, boolean, boolean)}
     * @param clear Method body of {@link Dataset#clear()}
     * @param fieldValues Constructor Arguments
     * @return Dataset Instance
     */
    public static synchronized Dataset compile(final String compute, final String clear,
        final Object... fieldValues) {
        final String source = String.format(
            "public Collection compute(RubyArray batch, boolean flush, boolean shutdown) { %s } public void clear() { %s }",
            compute, clear
        );
        try {
            final Class<?> clazz;
            if (CLASS_CACHE.containsKey(source)) {
                clazz = CLASS_CACHE.get(source);
            } else {
                final ClassBodyEvaluator se = new ClassBodyEvaluator();
                se.setImplementedInterfaces(new Class[]{Dataset.class});
                final String classname =
                    String.format("CompiledDataset%d", SEQUENCE.incrementAndGet());
                se.setClassName(classname);
                se.setDefaultImports(
                    new String[]{
                        "java.util.Collection", "java.util.Collections",
                        "org.logstash.config.ir.compiler.Dataset",
                        "org.logstash.ext.JrubyEventExtLibrary",
                        "org.logstash.RubyUtil", "org.logstash.config.ir.compiler.DatasetCompiler",
                        "org.jruby.runtime.Block", "org.jruby.RubyArray"
                    }
                );
                se.cook(new StringReader(fieldsAndCtor(classname, fieldValues) + source));
                clazz = se.getClazz();
                CLASS_CACHE.put(source, clazz);
            }
            final Class<?>[] args = new Class[fieldValues.length];
            Arrays.fill(args, Object.class);
            return (Dataset) clazz.getConstructor(args).newInstance(fieldValues);
        } catch (final CompileException | IOException | NoSuchMethodException
            | InvocationTargetException | InstantiationException | IllegalAccessException ex) {
            throw new IllegalStateException(ex);
        }
    }

    /**
     * <p>Builds a terminal {@link Dataset} from the given parent {@link Dataset}s.</p>
     * <p>If the given set of parent {@link Dataset} is empty the sum is defined as the
     * trivial dataset that does not invoke any computation whatsoever.</p>
     * {@link Dataset#compute(RubyArray, boolean, boolean)} is always
     * {@link Collections#emptyList()}.
     * @param parents Parent {@link Dataset} to sum and terminate
     * @return Dataset representing the sum of given parent {@link Dataset}
     */
    public static Dataset terminalDataset(final Collection<Dataset> parents) {
        final int count = parents.size();
        final Dataset result;
        if (count > 1) {
            final Object[] parentArr = parents.toArray();
            final int cnt = parentArr.length;
            final StringBuilder syntax = new StringBuilder();
            for (int i = 0; i < cnt; ++i) {
                syntax.append(computeDataset(i)).append(';');
            }
            for (int i = 0; i < cnt; ++i) {
                syntax.append(clear(i));
            }
            syntax.append(RETURN_NULL);
            result = compile(syntax.toString(), "", (Object[]) parentArr);
        } else if (count == 1) {
            // No need for a terminal dataset here, if there is only a single parent node we can
            // call it directly.
            result = parents.iterator().next();
        } else {
            result = EMPTY_DATASET;
        }
        return result;
    }

    /**
     * Compiles the {@link Dataset} representing an output plugin.
     * Note: The efficiency of the generated code rests on invoking the Ruby method
     * {@code multi_receive} in the cheapest possible way.
     * This is achieved by:
     * 1. Caching the method's {@link org.jruby.runtime.CallSite} into an instance
     * variable.
     * 2. Calling the low level CallSite invocation
     * {@link DynamicMethod#call(org.jruby.runtime.ThreadContext, IRubyObject, org.jruby.RubyModule, String, IRubyObject[], org.jruby.runtime.Block)}
     * using an {@code IRubyObject[]} field that is repopulated with the current Event array on
     * every call to {@code compute}.
     * @param parents Parent Datasets
     * @param output Output Plugin (of Ruby type OutputDelegator)
     * @param terminal Set to true if this output is the only output in the pipeline
     * @return Output Dataset
     */
    public static Dataset outputDataset(Collection<Dataset> parents, final IRubyObject output,
        final boolean terminal) {
        final String multiReceive = "multi_receive";
        final DynamicMethod method = output.getMetaClass().searchMethod(multiReceive);
        // Short-circuit trivial case of only output(s) in the pipeline
        if (parents == Dataset.ROOT_DATASETS) {
            return outputDatasetFromRoot(output, method);
        }
        final RubyArray buffer = RubyUtil.RUBY.newArray();
        final Object[] parentArr = parents.toArray();
        final int cnt = parentArr.length;
        final StringBuilder syntax = new StringBuilder();
        final int bufferIndex = cnt;
        for (int i = 0; i < cnt; ++i) {
            syntax.append("for (JrubyEventExtLibrary.RubyEvent event : ")
                .append(computeDataset(i)).append(") {")
                .append("if (!event.getEvent().isCancelled()) { ")
                .append(field(bufferIndex)).append(".add(event); } }");
        }
        final int callsiteIndex = cnt + 1;
        final int argArrayIndex = cnt + 2;
        final int pluginIndex = cnt + 3;
        syntax.append(callOutput(callsiteIndex, argArrayIndex, pluginIndex));
        syntax.append(clear(bufferIndex));
        final Object[] allArgs = new Object[cnt + 4];
        System.arraycopy(parentArr, 0, allArgs, 0, cnt);
        allArgs[bufferIndex] = buffer;
        allArgs[callsiteIndex] = method;
        allArgs[argArrayIndex] = new IRubyObject[]{buffer};
        allArgs[pluginIndex] = output;
        final StringBuilder clearSyntax = new StringBuilder();
        if (terminal) {
            for (int i = 0; i < cnt; ++i) {
                syntax.append(clear(i));
            }
        } else {
            for (int i = 0; i < cnt; ++i) {
                clearSyntax.append(clear(i));
            }
        }
        syntax.append(RETURN_NULL);
        return compile(syntax.toString(), clearSyntax.toString(), allArgs);
    }

    /**
     * Special case optimization for when the output plugin is directly connected to the Queue
     * without any filters or conditionals in between. This special case does not arise naturally
     * from {@link DatasetCompiler#outputDataset(Collection, IRubyObject, boolean)} since it saves
     * the internal buffering of events and instead forwards events directly from the batch to the
     * Output plugin.
     * @param output Output Plugin
     * @return Dataset representing the Output
     */
    private static Dataset outputDatasetFromRoot(final IRubyObject output,
        final DynamicMethod method) {
        final int argArrayIndex = 1;
        final StringBuilder syntax = new StringBuilder();
        syntax.append(field(argArrayIndex)).append("[0] = batch;");
        final int callsiteIndex = 0;
        final int pluginIndex = 2;
        syntax.append(callOutput(callsiteIndex, argArrayIndex, pluginIndex));
        final Object[] allArgs = new Object[3];
        allArgs[callsiteIndex] = method;
        allArgs[argArrayIndex] = new IRubyObject[1];
        allArgs[pluginIndex] = output;
        syntax.append(RETURN_NULL);
        return compile(syntax.toString(), "", allArgs);
    }

    /**
     * Generates the code for invoking the Output plugin's `multi_receive` method.
     * @param callsiteIndex Field index of the `multi_receive` call site
     * @param argArrayIndex Field index of the invocation argument array
     * @param pluginIndex Field index of the Output plugin's Ruby object
     * @return Java Code String
     */
    private static String callOutput(final int callsiteIndex, final int argArrayIndex,
        final int pluginIndex) {
        return new StringBuilder().append(field(callsiteIndex)).append(
            ".call(RubyUtil.RUBY.getCurrentContext(), ").append(field(pluginIndex))
            .append(", RubyUtil.LOGSTASH_MODULE, \"multi_receive\", ")
            .append(field(argArrayIndex)).append(", Block.NULL_BLOCK);").toString();
    }

    private static String clear(final int fieldIndex) {
        return String.format("%s.clear();", field(fieldIndex));
    }

    private static String computeDataset(final int fieldIndex) {
        return String.format("%s.compute(batch, flush, shutdown)", field(fieldIndex));
    }

    private static String field(final int id) {
        return String.format("field%d", id);
    }

    /**
     * Generates the Java code for defining one field and constructor argument for each given value.
     * @param classname Classname to generate constructor for
     * @param values Values to store in instance fields and to generate assignments in the
     * constructor for
     * @return Java Source String
     */
    private static String fieldsAndCtor(final String classname, final Object... values) {
        final StringBuilder result = new StringBuilder();
        int i = 0;
        for (final Object fieldValue : values) {
            result.append("private final ");
            result.append(typeName(fieldValue));
            result.append(' ').append(field(i)).append(';');
            ++i;
        }
        result.append("public ").append(classname).append('(');
        for (int k = 0; k < i; ++k) {
            if (k > 0) {
                result.append(',');
            }
            result.append("Object");
            result.append(' ').append(field(k));
        }
        result.append(')').append('{');
        int j = 0;
        for (final Object fieldValue : values) {
            final String fieldName = field(j);
            result.append("this.").append(fieldName).append('=').append(castToOwnType(fieldValue))
                .append(fieldName).append(';');
            ++j;
        }
        result.append('}');
        return result.toString();
    }

    /**
     * Generates a code-snippet typecast to the strictest possible type for the given object.
     * Example: Given a obj = "foo" the method generates {@code (java.lang.String) obj}
     * @param obj Object to generate type cast snippet for
     * @return Java Source Code
     */
    private static String castToOwnType(final Object obj) {
        return String.format("(%s)", typeName(obj));
    }

    /**
     * Returns the strictest possible syntax conform type for the given object. Note that for
     * any {@link Dataset} instance, this will be {@code org.logstash.config.ir.compiler.Dataset}
     * instead of a concrete class, since Dataset implementations are using runtime compiled
     * classes.
     * @param obj Object to lookup type name for
     * @return Syntax conform type name
     */
    private static String typeName(final Object obj) {
        final Class<?> clazz;
        if (obj instanceof Dataset) {
            clazz = Dataset.class;
        } else {
            clazz = obj.getClass();
        }
        return clazz.getTypeName();
    }

}
