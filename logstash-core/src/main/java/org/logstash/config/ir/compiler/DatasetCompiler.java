package org.logstash.config.ir.compiler;

import java.io.IOException;
import java.io.StringReader;
import java.lang.reflect.InvocationTargetException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Stream;
import org.codehaus.commons.compiler.CompileException;
import org.codehaus.janino.ClassBodyEvaluator;
import org.jruby.RubyArray;
import org.jruby.RubyHash;
import org.jruby.internal.runtime.methods.DynamicMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyEventExtLibrary;

/**
 * Compiler that can compile implementations of {@link Dataset} at runtime.
 */
public final class DatasetCompiler {

    /**
     * Argument passed to Ruby Filter flush method in generated code.
     */
    public static final IRubyObject[] FLUSH_FINAL = {flushOpts(true)};

    /**
     * Argument passed to Ruby Filter flush method in generated code.
     */
    public static final IRubyObject[] FLUSH_NOT_FINAL = {flushOpts(false)};

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
    private static final Dataset EMPTY_DATASET = DatasetCompiler.compile(RETURN_NULL, "");

    private static final String MULTI_FILTER = "multi_filter";

    private static final String MULTI_RECEIVE = "multi_receive";

    private static final String FLUSH = "flush";

    /**
     * Relative offset of the field holding the cached arguments used to invoke the
     * primary callsite of a dataset.
     */
    private static final int ARG_ARRAY_OFFSET = 0;

    /**
     * Relative offset of the primary (either multi_filter or multi_receive) {@link DynamicMethod}
     * callsite in generated code.
     */
    private static final int PRIMARY_CALLSITE_OFFSET = 1;

    /**
     * Relative offset of the field holding a wrapped Ruby plugin.
     */
    private static final int PLUGIN_FIELD_OFFSET = 2;

    /**
     * Relative offset of the field holding the collection used to buffer input
     * {@link JrubyEventExtLibrary.RubyEvent}.
     */
    private static final int INPUT_BUFFER_OFFSET = 3;

    /**
     * Relative offset of the field holding the collection used to buffer computed
     * {@link JrubyEventExtLibrary.RubyEvent}.
     */
    private static final int RESULT_BUFFER_OFFSET = 4;

    /**
     * Relative offset of the field holding the filter flush method callsite.
     */
    private static final int FLUSH_CALLSITE_OFFSET = 5;

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
        try {
            final Class<?> clazz;
            final String source = String.format(
                "public Collection compute(RubyArray batch, boolean flush, boolean shutdown) { %s } public void clear() { %s }",
                compute, clear
            );
            if (CLASS_CACHE.containsKey(source)) {
                clazz = CLASS_CACHE.get(source);
            } else {
                final ClassBodyEvaluator se = new ClassBodyEvaluator();
                se.setImplementedInterfaces(new Class[]{Dataset.class});
                final String classname =
                    String.format("CompiledDataset%d", SEQUENCE.incrementAndGet());
                se.setClassName(classname);
                se.setDefaultImports(
                    Stream.of(
                        Collection.class, Collections.class, Dataset.class,
                        JrubyEventExtLibrary.class, RubyUtil.class, DatasetCompiler.class,
                        Block.class, RubyArray.class
                    ).map(Class::getName).toArray(String[]::new)
                );
                se.cook(new StringReader(join(fieldsAndCtor(classname, fieldValues), source)));
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
     * Compiles a {@link Dataset} representing a filter plugin without flush behaviour.
     * @param parents Parent {@link Dataset} to aggregate for this filter
     * @param filter Filter Plugin
     * @return Dataset representing the filter plugin
     */
    public static Dataset filterDataset(final Collection<Dataset> parents,
        final IRubyObject filter) {
        final Object[] parentArr = parents.toArray();
        final int offset = parentArr.length;
        final Object[] allArgs = new Object[offset + 5];
        setupFilterFields(filter, parentArr, allArgs);
        return compileFilterDataset(offset, filterBody(offset), allArgs);
    }

    /**
     * Compiles a {@link Dataset} representing a filter plugin with flush behaviour.
     * @param parents Parent {@link Dataset} to aggregate for this filter
     * @param filter Filter Plugin
     * @param shutdownFlushOnly True iff plugin only flushes on shutdown
     * @return Dataset representing the filter plugin
     */
    public static Dataset flushingFilterDataset(final Collection<Dataset> parents,
        final IRubyObject filter, final boolean shutdownFlushOnly) {
        final Object[] parentArr = parents.toArray();
        final int offset = parentArr.length;
        final Object[] allArgs = new Object[offset + 6];
        setupFilterFields(filter, parentArr, allArgs);
        allArgs[offset + FLUSH_CALLSITE_OFFSET] = rubyCallsite(filter, FLUSH);
        return compileFilterDataset(
            offset, join(filterBody(offset), callFilterFlush(offset, shutdownFlushOnly)), allArgs
        );
    }

    private static void setupFilterFields(final IRubyObject filter, final Object[] parentArr,
        final Object[] allArgs) {
        final RubyArray buffer = RubyUtil.RUBY.newArray();
        final int offset = parentArr.length;
        System.arraycopy(parentArr, 0, allArgs, 0, offset);
        allArgs[offset + INPUT_BUFFER_OFFSET] = buffer;
        allArgs[offset + PRIMARY_CALLSITE_OFFSET] = rubyCallsite(filter, MULTI_FILTER);
        allArgs[offset + ARG_ARRAY_OFFSET] = new IRubyObject[]{buffer};
        allArgs[offset + PLUGIN_FIELD_OFFSET] = filter;
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
            final int offset = parentArr.length;
            final StringBuilder syntax = new StringBuilder();
            for (int i = 0; i < offset; ++i) {
                syntax.append(computeDataset(i)).append(';');
            }
            result = compileOutput(join(syntax.toString(), clearSyntax(offset)), "", parentArr);
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
     * {@link DynamicMethod#call(org.jruby.runtime.ThreadContext, IRubyObject, org.jruby.RubyModule, String, IRubyObject[], Block)}
     * using an {@code IRubyObject[]} field that is repopulated with the current Event array on
     * every call to {@code compute}.
     * @param parents Parent Datasets
     * @param output Output Plugin (of Ruby type OutputDelegator)
     * @param terminal Set to true if this output is the only output in the pipeline
     * @return Output Dataset
     */
    public static Dataset outputDataset(final Collection<Dataset> parents, final IRubyObject output,
        final boolean terminal) {
        final DynamicMethod method = rubyCallsite(output, MULTI_RECEIVE);
        // Short-circuit trivial case of only output(s) in the pipeline
        if (parents == Dataset.ROOT_DATASETS) {
            return outputDatasetFromRoot(output, method);
        }
        final RubyArray buffer = RubyUtil.RUBY.newArray();
        final Object[] parentArr = parents.toArray();
        final int offset = parentArr.length;
        final Object[] allArgs = new Object[offset + 4];
        System.arraycopy(parentArr, 0, allArgs, 0, offset);
        allArgs[offset + INPUT_BUFFER_OFFSET] = buffer;
        allArgs[offset + PRIMARY_CALLSITE_OFFSET] = method;
        allArgs[offset + ARG_ARRAY_OFFSET] = new IRubyObject[]{buffer};
        allArgs[offset + PLUGIN_FIELD_OFFSET] = output;
        final String clearSyntax;
        final String inlineClear;
        if (terminal) {
            clearSyntax = "";
            inlineClear = clearSyntax(offset);
        } else {
            inlineClear = "";
            clearSyntax = clearSyntax(offset);
        }
        return compileOutput(
            join(
                join(
                    bufferForOutput(offset), callOutput(offset), clear(offset + INPUT_BUFFER_OFFSET)
                ), inlineClear
            ), clearSyntax, allArgs
        );
    }

    private static String callFilterFlush(final int offset, final boolean shutdownOnly) {
        final String condition;
        final String flushArgs;
        if (shutdownOnly) {
            condition = "flush && shutdown";
            flushArgs = "DatasetCompiler.FLUSH_FINAL";
        } else {
            condition = "flush";
            flushArgs = "shutdown ? DatasetCompiler.FLUSH_FINAL : DatasetCompiler.FLUSH_NOT_FINAL";
        }
        return join(
            "if(", condition, "){", field(offset + RESULT_BUFFER_OFFSET), ".addAll((RubyArray)",
            callRubyCallsite(FLUSH_CALLSITE_OFFSET, flushArgs, offset, FLUSH), ");}"
        );
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
            result.append(join("private final ", typeName(fieldValue), " ", field(i), ";"));
            ++i;
        }
        result.append(join("public ", classname, "("));
        for (int k = 0; k < i; ++k) {
            if (k > 0) {
                result.append(',');
            }
            result.append(join("Object ", field(k)));
        }
        result.append(") {");
        int j = 0;
        for (final Object fieldValue : values) {
            final String fieldName = field(j);
            result.append(join("this.", fieldName, "=", castToOwnType(fieldValue), fieldName, ";"));
            ++j;
        }
        result.append('}');
        return result.toString();
    }

    private static IRubyObject flushOpts(final boolean fin) {
        final RubyHash res = RubyHash.newHash(RubyUtil.RUBY);
        res.put(RubyUtil.RUBY.newSymbol("final"), RubyUtil.RUBY.newBoolean(fin));
        return res;
    }

    private static String bufferForOutput(final int offset) {
        final StringBuilder syntax = new StringBuilder();
        for (int i = 0; i < offset; ++i) {
            syntax.append(
                join(
                    "for (JrubyEventExtLibrary.RubyEvent e : ", computeDataset(i), ") {",
                    "if (!e.getEvent().isCancelled()) { ", field(offset + INPUT_BUFFER_OFFSET),
                    ".add(e); } }"
                )
            );
        }
        return syntax.toString();
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
        final Object[] allArgs = new Object[3];
        allArgs[PRIMARY_CALLSITE_OFFSET] = method;
        allArgs[ARG_ARRAY_OFFSET] = new IRubyObject[1];
        allArgs[PLUGIN_FIELD_OFFSET] = output;
        return compileOutput(
            join(field(ARG_ARRAY_OFFSET), "[0] = batch;", callOutput(0)), "",
            allArgs
        );
    }

    private static Dataset compileOutput(final String syntax, final String clearSyntax,
        final Object[] allArgs) {
        return compile(join(syntax, RETURN_NULL), clearSyntax, allArgs);
    }

    /**
     * Generates the code for invoking the Output plugin's `multi_receive` method.
     * @param offset Number of Parent Dataset Fields
     * @return Java Code String
     */
    private static String callOutput(final int offset) {
        return join(
            callRubyCallsite(
                PRIMARY_CALLSITE_OFFSET, field(offset + ARG_ARRAY_OFFSET), offset, MULTI_RECEIVE
            ), ";"
        );
    }

    private static String callFilter(final int offset) {
        return join(
            field(offset + RESULT_BUFFER_OFFSET), ".addAll((RubyArray)",
            callRubyCallsite(
                PRIMARY_CALLSITE_OFFSET, field(offset + ARG_ARRAY_OFFSET), offset, MULTI_FILTER
            ), ");"
        );
    }

    private static String callRubyCallsite(final int callsiteOffset, final String argument,
        final int offset, final String method) {
        return join(
            field(offset + callsiteOffset), ".call(RubyUtil.RUBY.getCurrentContext(), ",
            field(offset + PLUGIN_FIELD_OFFSET),
            ", RubyUtil.LOGSTASH_MODULE,", join("\"", method, "\""), ", ", argument,
            ", Block.NULL_BLOCK)"
        );
    }

    private static Dataset compileFilterDataset(final int offset, final String syntax,
        final Object[] allArgs) {
        allArgs[offset + RESULT_BUFFER_OFFSET] = new ArrayList<>();
        return compile(
            join(syntax, "return ", field(offset + RESULT_BUFFER_OFFSET), ";"),
            join(clearSyntax(offset), clear(offset + RESULT_BUFFER_OFFSET)), allArgs
        );
    }

    private static String clearSyntax(final int count) {
        final StringBuilder syntax = new StringBuilder();
        for (int i = 0; i < count; ++i) {
            syntax.append(clear(i));
        }
        return syntax.toString();
    }

    private static DynamicMethod rubyCallsite(final IRubyObject rubyObject, final String name) {
        return rubyObject.getMetaClass().searchMethod(name);
    }

    private static String evalParents(final int count) {
        final StringBuilder syntax = new StringBuilder();
        for (int i = 0; i < count; ++i) {
            syntax.append(
                join(field(count + INPUT_BUFFER_OFFSET), ".addAll(", computeDataset(i), ");")
            );
        }
        return syntax.toString();
    }

    private static String filterBody(final int offset) {
        return join(evalParents(offset), callFilter(offset), clear(offset + INPUT_BUFFER_OFFSET));
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
        final String classname = clazz.getTypeName();
        // JavaFilterDelegator classes are runtime generated by Ruby and are not available
        // to the Janino compiler's classloader. There is no value in casting to the concrete class
        // here anyways since JavaFilterDelegator instances are only passed as IRubyObject type
        // method parameters in the generated code.
        return classname.contains("JavaFilterDelegator")
            ? IRubyObject.class.getTypeName() : classname;
    }

    private static String join(final String... parts) {
        return String.join("", parts);
    }
}
