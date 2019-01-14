package org.logstash.config.ir.compiler;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.stream.Collectors;
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

    private static final String MULTI_RECEIVE = "multi_receive";

    private static final String FLUSH = "flush";

    public static final SyntaxFactory.IdentifierStatement FLUSH_ARG =
        SyntaxFactory.identifier("flushArg");

    public static final SyntaxFactory.IdentifierStatement SHUTDOWN_ARG =
        SyntaxFactory.identifier("shutdownArg");

    public static final SyntaxFactory.IdentifierStatement BATCH_ARG =
        SyntaxFactory.identifier("batchArg");

    /**
     * Root {@link Dataset}s at the beginning of the execution tree that simply pass through
     * the given set of {@link JrubyEventExtLibrary.RubyEvent} and have no state.
     */
    public static final Collection<Dataset> ROOT_DATASETS = Collections.singleton(
        prepare(Closure.wrap(SyntaxFactory.ret(BATCH_ARG)), Closure.EMPTY, new ClassFields())
            .instantiate()
    );

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
    public static synchronized ComputeStepSyntaxElement<Dataset> prepare(final Closure compute, final Closure clear,
        final ClassFields fieldValues) {
        return new ComputeStepSyntaxElement<>(
            Arrays.asList(MethodSyntaxElement.compute(compute), MethodSyntaxElement.clear(clear)),
            fieldValues, Dataset.class
        );
    }

    public static ComputeStepSyntaxElement<SplitDataset> splitDataset(final Collection<Dataset> parents,
        final EventCondition condition) {
        final ClassFields fields = new ClassFields();
        final Collection<ValueSyntaxElement> parentFields =
            parents.stream().map(fields::add).collect(Collectors.toList());
        final SyntaxElement arrayInit =
            SyntaxFactory.constant(RubyUtil.class, "RUBY").call("newArray");
        final ValueSyntaxElement ifData = fields.add(RubyArray.class, arrayInit);
        final ValueSyntaxElement elseData = fields.add(RubyArray.class, arrayInit);
        final ValueSyntaxElement buffer = fields.add(RubyArray.class, arrayInit);
        final ValueSyntaxElement done = fields.add(boolean.class);
        final VariableDefinition event =
            new VariableDefinition(JrubyEventExtLibrary.RubyEvent.class, "event");
        final ValueSyntaxElement eventVal = event.access();
        return new ComputeStepSyntaxElement<>(
            Arrays.asList(
                MethodSyntaxElement.compute(
                    returnIffBuffered(ifData, done)
                        .add(bufferParents(parentFields, buffer))
                        .add(
                            SyntaxFactory.forLoop(
                                event, buffer,
                                Closure.wrap(
                                    SyntaxFactory.ifCondition(
                                        fields.add(condition).call("fulfilled", eventVal),
                                        Closure.wrap(ifData.call("add", eventVal)),
                                        Closure.wrap(elseData.call("add", eventVal))
                                    )
                                )
                            )
                        ).add(clear(buffer))
                        .add(SyntaxFactory.assignment(done, SyntaxFactory.TRUE))
                        .add(SyntaxFactory.ret(ifData))
                ),
                MethodSyntaxElement.clear(
                    clearSyntax(parentFields).add(clear(ifData)).add(clear(elseData))
                        .add(SyntaxFactory.assignment(done, SyntaxFactory.FALSE))
                ),
                MethodSyntaxElement.right(elseData)
            ), fields, SplitDataset.class
        );
    }

    /**
     * Compiles a {@link Dataset} representing a filter plugin without flush behaviour.
     * @param parents Parent {@link Dataset} to aggregate for this filter
     * @param plugin Filter Plugin
     * @return Dataset representing the filter plugin
     */
    public static ComputeStepSyntaxElement<Dataset> filterDataset(final Collection<Dataset> parents,
        final RubyIntegration.Filter plugin) {
        final ClassFields fields = new ClassFields();
        final Collection<ValueSyntaxElement> parentFields =
            parents.stream().map(fields::add).collect(Collectors.toList());
        final RubyArray inputBuffer = RubyUtil.RUBY.newArray();
        final ValueSyntaxElement inputBufferField = fields.add(inputBuffer);
        final ValueSyntaxElement outputBuffer = fields.add(new ArrayList<>());
        final IRubyObject filter = plugin.toRuby();
        final ValueSyntaxElement filterField = fields.add(filter);
        final ValueSyntaxElement done = fields.add(boolean.class);
        final String multiFilter = "multi_filter";
        final Closure body = returnIffBuffered(outputBuffer, done).add(
            bufferParents(parentFields, inputBufferField)
                .add(
                    buffer(
                        outputBuffer,
                        SyntaxFactory.cast(
                            RubyArray.class,
                            callRubyCallsite(
                                fields.add(rubyCallsite(filter, multiFilter)),
                                fields.add(new IRubyObject[]{inputBuffer}), filterField,
                                multiFilter
                            )
                        )
                    )
                ).add(clear(inputBufferField))
        );
        if (plugin.hasFlush()) {
            body.add(
                callFilterFlush(
                    fields, outputBuffer, fields.add(rubyCallsite(filter, FLUSH)), filterField,
                    !plugin.periodicFlush()
                )
            );
        }
        return prepare(
            body.add(SyntaxFactory.assignment(done, SyntaxFactory.TRUE))
                .add(SyntaxFactory.ret(outputBuffer)),
            Closure.wrap(
                clearSyntax(parentFields), clear(outputBuffer),
                SyntaxFactory.assignment(done, SyntaxFactory.FALSE)
            ), fields
        );
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
            final ClassFields fields = new ClassFields();
            final Collection<ValueSyntaxElement> parentFields =
                parents.stream().map(fields::add).collect(Collectors.toList());
            result = compileOutput(
                Closure.wrap(
                    parentFields.stream().map(DatasetCompiler::computeDataset)
                        .toArray(MethodLevelSyntaxElement[]::new)
                ).add(clearSyntax(parentFields)), Closure.EMPTY, fields
            ).instantiate();
        } else if (count == 1) {
            // No need for a terminal dataset here, if there is only a single parent node we can
            // call it directly.
            result = parents.iterator().next();
        } else {
            throw new IllegalArgumentException(
                "Cannot create Terminal Dataset for an empty number of parent datasets"
            );
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
    public static ComputeStepSyntaxElement<Dataset> outputDataset(final Collection<Dataset> parents,
        final IRubyObject output,
        final boolean terminal) {
        final DynamicMethod method = rubyCallsite(output, MULTI_RECEIVE);
        // Short-circuit trivial case of only output(s) in the pipeline
        if (parents == ROOT_DATASETS) {
            return outputDatasetFromRoot(output, method);
        }
        final ClassFields fields = new ClassFields();
        final Collection<ValueSyntaxElement> parentFields =
            parents.stream().map(fields::add).collect(Collectors.toList());
        final RubyArray buffer = RubyUtil.RUBY.newArray();
        final ValueSyntaxElement inputBuffer = fields.add(buffer);
        final Closure clearSyntax;
        final Closure inlineClear;
        if (terminal) {
            clearSyntax = Closure.EMPTY;
            inlineClear = clearSyntax(parentFields);
        } else {
            inlineClear = Closure.EMPTY;
            clearSyntax = clearSyntax(parentFields);
        }
        return compileOutput(
            Closure.wrap(
                bufferParents(parentFields, inputBuffer),
                callRubyCallsite(
                    fields.add(method), fields.add(new IRubyObject[]{buffer}),
                    fields.add(output), MULTI_RECEIVE
                ),
                clear(inputBuffer),
                inlineClear
            ),
            clearSyntax, fields
        );
    }

    private static Closure returnIffBuffered(final MethodLevelSyntaxElement ifData,
        final MethodLevelSyntaxElement done) {
        return Closure.wrap(
            SyntaxFactory.ifCondition(done, Closure.wrap(SyntaxFactory.ret(ifData)))
        );
    }

    private static MethodLevelSyntaxElement callFilterFlush(final ClassFields fields,
        final ValueSyntaxElement resultBuffer, final ValueSyntaxElement flushMethod,
        final ValueSyntaxElement filterPlugin, final boolean shutdownOnly) {
        final MethodLevelSyntaxElement condition;
        final ValueSyntaxElement flushArgs;
        final ValueSyntaxElement flushFinal = fields.add(flushOpts(true));
        if (shutdownOnly) {
            condition = SyntaxFactory.and(FLUSH_ARG, SHUTDOWN_ARG);
            flushArgs = flushFinal;
        } else {
            condition = FLUSH_ARG;
            flushArgs = SyntaxFactory.ternary(
                SHUTDOWN_ARG, flushFinal, fields.add(flushOpts(false))
            );
        }
        return SyntaxFactory.ifCondition(
            condition,
            Closure.wrap(
                buffer(
                    resultBuffer,
                    SyntaxFactory.cast(
                        RubyArray.class,
                        callRubyCallsite(flushMethod, flushArgs, filterPlugin, FLUSH)
                    )
                )
            )
        );
    }

    private static MethodLevelSyntaxElement clear(final ValueSyntaxElement field) {
        return field.call("clear");
    }

    private static ValueSyntaxElement computeDataset(final ValueSyntaxElement parent) {
        return parent.call("compute", BATCH_ARG, FLUSH_ARG, SHUTDOWN_ARG);
    }

    private static IRubyObject[] flushOpts(final boolean fin) {
        final RubyHash res = RubyHash.newHash(RubyUtil.RUBY);
        res.put(RubyUtil.RUBY.newSymbol("final"), RubyUtil.RUBY.newBoolean(fin));
        return new IRubyObject[]{res};
    }

    private static Closure bufferParents(final Collection<ValueSyntaxElement> parents,
        final ValueSyntaxElement buffer) {
        final VariableDefinition event =
            new VariableDefinition(JrubyEventExtLibrary.RubyEvent.class, "e");
        final ValueSyntaxElement eventVar = event.access();
        return Closure.wrap(
            parents.stream().map(par ->
                SyntaxFactory.forLoop(
                    event, computeDataset(par),
                    Closure.wrap(
                        SyntaxFactory.ifCondition(
                            SyntaxFactory.not(
                                eventVar.call("getEvent").call("isCancelled")
                            ), Closure.wrap(buffer.call("add", eventVar))
                        )
                    )
                )
            ).toArray(MethodLevelSyntaxElement[]::new)
        );
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
    private static ComputeStepSyntaxElement<Dataset> outputDatasetFromRoot(final IRubyObject output,
        final DynamicMethod method) {
        final ClassFields fields = new ClassFields();
        final ValueSyntaxElement args = fields.add(new IRubyObject[1]);
        return compileOutput(
            Closure.wrap(
                SyntaxFactory.assignment(SyntaxFactory.arrayField(args, 0), BATCH_ARG),
                callRubyCallsite(fields.add(method), args, fields.add(output), MULTI_RECEIVE)
            ),
            Closure.EMPTY, fields
        );
    }

    private static ComputeStepSyntaxElement<Dataset> compileOutput(final Closure syntax,
        final Closure clearSyntax, final ClassFields fields) {
        return prepare(
            syntax.add(MethodLevelSyntaxElement.RETURN_NULL), clearSyntax, fields
        );
    }

    private static MethodLevelSyntaxElement buffer(final ValueSyntaxElement resultBuffer,
        final ValueSyntaxElement argument) {
        return resultBuffer.call("addAll", argument);
    }

    private static ValueSyntaxElement callRubyCallsite(final ValueSyntaxElement callsite,
        final ValueSyntaxElement argument, final ValueSyntaxElement plugin, final String method) {
        return callsite.call(
            "call",
            ValueSyntaxElement.GET_RUBY_THREAD_CONTEXT,
            plugin,
            SyntaxFactory.constant(RubyUtil.class, "LOGSTASH_MODULE"),
            SyntaxFactory.value(SyntaxFactory.join("\"", method, "\"")),
            argument,
            SyntaxFactory.constant(Block.class, "NULL_BLOCK")
        );
    }

    private static Closure clearSyntax(final Collection<ValueSyntaxElement> toClear) {
        return Closure.wrap(
            toClear.stream().map(DatasetCompiler::clear).toArray(MethodLevelSyntaxElement[]::new)
        );
    }

    private static DynamicMethod rubyCallsite(final IRubyObject rubyObject, final String name) {
        return rubyObject.getMetaClass().searchMethod(name);
    }

    /**
     * Complementary {@link Dataset} to a {@link SplitDataset} representing the
     * negative branch of the {@code if} statement.
     */
    public static final class Complement implements Dataset {

        /**
         * Positive branch of underlying {@code if} statement.
         */
        private final Dataset parent;

        /**
         * This collection is shared with {@link DatasetCompiler.Complement#parent} and
         * mutated when calling its {@code compute} method. This class does not directly compute
         * it.
         */
        private final Collection<JrubyEventExtLibrary.RubyEvent> data;

        private boolean done;

        public static Dataset from(final Dataset parent,
            final Collection<JrubyEventExtLibrary.RubyEvent> complement) {
            return new DatasetCompiler.Complement(parent, complement);
        }

        /**
         * Ctor.
         * @param left Positive Branch {@link SplitDataset}
         * @param complement Collection of {@link JrubyEventExtLibrary.RubyEvent}s that did
         * not match {@code left}
         */
        private Complement(
            final Dataset left, final Collection<JrubyEventExtLibrary.RubyEvent> complement) {
            this.parent = left;
            data = complement;
        }

        @Override
        public Collection<JrubyEventExtLibrary.RubyEvent> compute(final RubyArray batch,
            final boolean flush, final boolean shutdown) {
            if (done) {
                return data;
            }
            parent.compute(batch, flush, shutdown);
            done = true;
            return data;
        }

        @Override
        public void clear() {
            parent.clear();
            done = false;
        }
    }
}
