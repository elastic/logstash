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

    private static final String FLUSH = "flush";

    public static final SyntaxFactory.IdentifierStatement FLUSH_ARG =
        SyntaxFactory.identifier("flushArg");

    public static final SyntaxFactory.IdentifierStatement SHUTDOWN_ARG =
        SyntaxFactory.identifier("shutdownArg");

    public static final SyntaxFactory.IdentifierStatement BATCH_ARG =
        SyntaxFactory.identifier("batchArg");

    private DatasetCompiler() {
        // Utility Class
    }

    public static ComputeStepSyntaxElement<SplitDataset> splitDataset(
        final Collection<Dataset> parents,
        final EventCondition condition)
    {
        final ClassFields fields = new ClassFields();
        final ValueSyntaxElement ifData = fields.add(new ArrayList<>());
        final ValueSyntaxElement elseData = fields.add(new ArrayList<>());
        final ValueSyntaxElement right = fields.add(DatasetCompiler.Complement.class);
        final VariableDefinition event =
            new VariableDefinition(JrubyEventExtLibrary.RubyEvent.class, "event");
        fields.addAfterInit(
            Closure.wrap(
                SyntaxFactory.assignment(
                    right,
                    SyntaxFactory.cast(
                        DatasetCompiler.Complement.class, SyntaxFactory.constant(
                            DatasetCompiler.class, DatasetCompiler.Complement.class.getSimpleName()
                        ).call("from", SyntaxFactory.identifier("this"), elseData)
                    )
                )
            )
        );
        final ValueSyntaxElement conditionField = fields.add(condition);
        final DatasetCompiler.ComputeAndClear compute;
        if (parents.isEmpty()) {
            compute = withOutputBuffering(
                conditionalLoop(event, BATCH_ARG, conditionField, ifData, elseData),
                Closure.wrap(clear(elseData)), ifData, fields
            );
        } else {
            final Collection<ValueSyntaxElement> parentFields =
                parents.stream().map(fields::add).collect(Collectors.toList());
            final ValueSyntaxElement inputBuffer = fields.add(new ArrayList<>());
            compute = withOutputBuffering(
                withInputBuffering(
                    conditionalLoop(event, inputBuffer, conditionField, ifData, elseData),
                    parentFields, inputBuffer
                ),
                clearSyntax(parentFields).add(clear(elseData)), ifData, fields
            );
        }
        return ComputeStepSyntaxElement.create(
            Arrays.asList(compute.compute(), compute.clear(), MethodSyntaxElement.right(right)),
            compute.fields(), SplitDataset.class
        );
    }

    /**
     * Compiles a {@link Dataset} representing a filter plugin without flush behaviour.
     * @param parents Parent {@link Dataset} to aggregate for this filter
     * @param plugin Filter Plugin
     * @return Dataset representing the filter plugin
     */
    public static ComputeStepSyntaxElement<Dataset> filterDataset(
        final Collection<Dataset> parents,
        final AbstractFilterDelegatorExt plugin)
    {
        final ClassFields fields = new ClassFields();
        final ValueSyntaxElement outputBuffer = fields.add(new ArrayList<>());
        final Closure clear = Closure.wrap();
        final Closure compute;
        if (parents.isEmpty()) {
            compute = filterBody(outputBuffer, BATCH_ARG, fields, plugin);
        } else {
            final Collection<ValueSyntaxElement> parentFields = parents
                .stream()
                .map(fields::add)
                .collect(Collectors.toList()
            );
            @SuppressWarnings("rawtypes") final RubyArray inputBuffer = RubyUtil.RUBY.newArray();
            clear.add(clearSyntax(parentFields));
            final ValueSyntaxElement inputBufferField = fields.add(inputBuffer);
            compute = withInputBuffering(
                filterBody(outputBuffer, inputBufferField, fields, plugin),
                parentFields, inputBufferField
            );
        }
        return prepare(withOutputBuffering(compute, clear, outputBuffer, fields));
    }

    /**
     * <p>Builds a terminal {@link Dataset} for the filters from the given parent {@link Dataset}s.</p>
     * <p>If the given set of parent {@link Dataset} is empty the sum is defined as the
     * trivial dataset that does not invoke any computation whatsoever.</p>
     * {@link Dataset#compute(RubyArray, boolean, boolean)} is always
     * {@link Collections#emptyList()}.
     * @param parents Parent {@link Dataset} to sum
     * @return Dataset representing the sum of given parent {@link Dataset}
     */
    public static Dataset terminalFilterDataset(final Collection<Dataset> parents) {
        if (parents.isEmpty()) {
            return Dataset.IDENTITY;
        }

        final int count = parents.size();
        if (count == 1) {
            // No need for a terminal dataset here, if there is only a single parent node we can
            // call it directly.
            return parents.iterator().next();
        }

        final ClassFields fields = new ClassFields();
        final Collection<ValueSyntaxElement> parentFields = parents
            .stream()
            .map(fields::add)
            .collect(Collectors.toList());
        @SuppressWarnings("rawtypes") final RubyArray inputBuffer = RubyUtil.RUBY.newArray();
        final ValueSyntaxElement inputBufferField = fields.add(inputBuffer);
        final ValueSyntaxElement outputBufferField = fields.add(new ArrayList<>());
        final Closure clear = Closure.wrap().add(clearSyntax(parentFields));
        final Closure compute = withInputBuffering(
            Closure.wrap(
                // pass thru filter
                buffer(outputBufferField, inputBufferField)
            ),
            parentFields,
            inputBufferField
        );

        return prepare(withOutputBuffering(compute, clear, outputBufferField, fields)).instantiate();
    }

    /**
     * <p>Builds a terminal {@link Dataset} for the outputs from the given parent {@link Dataset}s.</p>
     * <p>If the given set of parent {@link Dataset} is empty the sum is defined as the
     * trivial dataset that does not invoke any computation whatsoever.</p>
     * {@link Dataset#compute(RubyArray, boolean, boolean)} is always
     * {@link Collections#emptyList()}.
     * @param parents Parent {@link Dataset} to sum and terminate
     * @return Dataset representing the sum of given parent {@link Dataset}
     */
    public static Dataset terminalOutputDataset(final Collection<Dataset> parents) {
        if (parents.isEmpty()) {
            throw new IllegalArgumentException(
                "Cannot create terminal output dataset for an empty number of parent datasets"
            );
        }

        final int count = parents.size();
        if (count == 1) {
            // No need for a terminal dataset here, if there is only a single parent node we can
            // call it directly.
            return parents.iterator().next();
        }

        final ClassFields fields = new ClassFields();
        final Collection<ValueSyntaxElement> parentFields = parents
            .stream()
            .map(fields::add)
            .collect(Collectors.toList());
        final Closure compute =  Closure.wrap(parentFields
                .stream()
                .map(DatasetCompiler::computeDataset)
                .toArray(MethodLevelSyntaxElement[]::new)
        ).add(clearSyntax(parentFields));

        return compileOutput(compute, Closure.EMPTY, fields).instantiate();
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
    public static ComputeStepSyntaxElement<Dataset> outputDataset(
        final Collection<Dataset> parents,
        final AbstractOutputDelegatorExt output,
        final boolean terminal)
    {
        final ClassFields fields = new ClassFields();
        final Closure clearSyntax;
        final Closure computeSyntax;
        final ValueSyntaxElement outputField = fields.add(output);
        if (parents.isEmpty()) {
            clearSyntax = Closure.EMPTY;
            computeSyntax = Closure.wrap(
                setPluginIdForLog4j(outputField),
                invokeOutput(outputField, BATCH_ARG),
                unsetPluginIdForLog4j());
        } else {
            final Collection<ValueSyntaxElement> parentFields =
                parents.stream().map(fields::add).collect(Collectors.toList());
            @SuppressWarnings("rawtypes")
            final RubyArray buffer = RubyUtil.RUBY.newArray();
            final Closure inlineClear;
            if (terminal) {
                clearSyntax = Closure.EMPTY;
                inlineClear = clearSyntax(parentFields);
            } else {
                inlineClear = Closure.EMPTY;
                clearSyntax = clearSyntax(parentFields);
            }
            final ValueSyntaxElement inputBuffer = fields.add(buffer);
            computeSyntax = withInputBuffering(
                Closure.wrap(
                    setPluginIdForLog4j(outputField),
                    invokeOutput(outputField, inputBuffer),
                    inlineClear,
                    unsetPluginIdForLog4j()
                ),
                parentFields, inputBuffer
            );
        }
        return compileOutput(computeSyntax, clearSyntax, fields);
    }

    private static ValueSyntaxElement invokeOutput(
        final ValueSyntaxElement output,
        final MethodLevelSyntaxElement events)
    {
        return output.call("multiReceive", events);
    }

    private static Closure filterBody(
        final ValueSyntaxElement outputBuffer,
        final ValueSyntaxElement inputBuffer,
        final ClassFields fields,
        final AbstractFilterDelegatorExt plugin)
    {
        final ValueSyntaxElement filterField = fields.add(plugin);
        final Closure body = Closure.wrap(
            setPluginIdForLog4j(filterField),
            buffer(outputBuffer, filterField.call("multiFilter", inputBuffer))
        );
        if (plugin.hasFlush()) {
            body.add(callFilterFlush(fields, outputBuffer, filterField, !plugin.periodicFlush()));
        }
        body.add(unsetPluginIdForLog4j());
        return body;
    }

    private static Closure conditionalLoop(final VariableDefinition event,
        final MethodLevelSyntaxElement inputBuffer, final ValueSyntaxElement condition,
        final ValueSyntaxElement ifData, final ValueSyntaxElement elseData) {
        final ValueSyntaxElement eventVal = event.access();
        return Closure.wrap(
            SyntaxFactory.value("org.logstash.config.ir.compiler.Utils").call(
                "filterEvents",
                inputBuffer,
                condition,
                ifData,
                elseData
            )
        );
    }

    /**
     * Compiles and subsequently instantiates a {@link Dataset} from given code snippets and
     * constructor arguments.
     * This method must be {@code synchronized} to avoid compiling duplicate classes.
     * @param compute Method definitions for {@code compute} and {@code clear}
     * @return Dataset Instance
     */
    private static ComputeStepSyntaxElement<Dataset> prepare(final DatasetCompiler.ComputeAndClear compute) {
        return ComputeStepSyntaxElement.create(
            Arrays.asList(compute.compute(), compute.clear()), compute.fields(), Dataset.class
        );
    }

    /**
     * Generates code that buffers all events that aren't cancelled from a given set of parent
     * {@link Dataset} to a given collection, executes the given closure and then clears the
     * collection used for buffering.
     * @param compute Closure to execute
     * @param parents Parents to buffer results for
     * @param inputBuffer Buffer to store results in
     * @return Closure wrapped by buffering parent results and clearing them
     */
    private static Closure withInputBuffering(final Closure compute,
        final Collection<ValueSyntaxElement> parents, final ValueSyntaxElement inputBuffer) {
        return Closure.wrap(
                parents.stream().map(par -> SyntaxFactory.value("org.logstash.config.ir.compiler.Utils")
                        .call("copyNonCancelledEvents", computeDataset(par), inputBuffer)
                ).toArray(MethodLevelSyntaxElement[]::new)
        ).add(compute).add(clear(inputBuffer));
    }

    /**
     * Generates compute and clear actions with logic for setting a boolean {@code done}
     * flag and caching the result of the computation in the {@code compute} closure.
     * Wraps {@code clear} closure with condition to only execute the clear if the {@code done}
     * flag is set to {@code true}. Also adds clearing the output buffer used for caching the
     * {@code compute} result to the {@code clear} closure.
     * @param compute Compute closure to execute
     * @param clear Clear closure to execute
     * @param outputBuffer Output buffer used for caching {@code compute} result
     * @param fields Class fields
     * @return ComputeAndClear with adjusted methods and {@code done} flag added to fields
     */
    private static DatasetCompiler.ComputeAndClear withOutputBuffering(final Closure compute,
        final Closure clear, final ValueSyntaxElement outputBuffer, final ClassFields fields) {
        final SyntaxFactory.MethodCallReturnValue done = new SyntaxFactory.MethodCallReturnValue(SyntaxFactory.value("this"), "isDone");
        return computeAndClear(
            Closure.wrap(
                SyntaxFactory.ifCondition(done, Closure.wrap(SyntaxFactory.ret(outputBuffer)))
            ).add(compute)
                .add(new SyntaxFactory.MethodCallReturnValue(SyntaxFactory.value("this"), "setDone"))
                .add(SyntaxFactory.ret(outputBuffer)),
            Closure.wrap(
                SyntaxFactory.ifCondition(
                    done, Closure.wrap(
                        clear.add(clear(outputBuffer)),
                        new SyntaxFactory.MethodCallReturnValue(SyntaxFactory.value("this"), "clearDone")
                    )
                )
            ), fields
        );
    }

    private static MethodLevelSyntaxElement callFilterFlush(final ClassFields fields,
        final ValueSyntaxElement resultBuffer, final ValueSyntaxElement filterPlugin,
        final boolean shutdownOnly) {
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
            condition, Closure.wrap(buffer(resultBuffer, filterPlugin.call(FLUSH, flushArgs)))
        );
    }

    private static MethodLevelSyntaxElement unsetPluginIdForLog4j() {
        return SyntaxFactory.value("org.apache.logging.log4j.ThreadContext").call(
                "remove",
                SyntaxFactory.value("\"plugin.id\"")
        );
    }

    private static MethodLevelSyntaxElement setPluginIdForLog4j(final ValueSyntaxElement plugin) {
        return SyntaxFactory.value("org.apache.logging.log4j.ThreadContext").call(
                "put",
                SyntaxFactory.value("\"plugin.id\""),
                plugin.call("getId").call("toString")
        );
    }

    private static MethodLevelSyntaxElement clear(final ValueSyntaxElement field) {
        return field.call("clear");
    }

    private static ValueSyntaxElement computeDataset(final ValueSyntaxElement parent) {
        return parent.call("compute", BATCH_ARG, FLUSH_ARG, SHUTDOWN_ARG);
    }

    private static RubyHash flushOpts(final boolean fin) {
        final RubyHash res = RubyHash.newHash(RubyUtil.RUBY);
        res.put(RubyUtil.RUBY.newSymbol("final"), RubyUtil.RUBY.newBoolean(fin));
        return res;
    }

    private static ComputeStepSyntaxElement<Dataset> compileOutput(final Closure syntax,
        final Closure clearSyntax, final ClassFields fields) {
        return prepare(
            computeAndClear(syntax.add(MethodLevelSyntaxElement.RETURN_NULL), clearSyntax, fields)
        );
    }

    private static MethodLevelSyntaxElement buffer(
        final ValueSyntaxElement resultBuffer,
        final ValueSyntaxElement argument)
    {
        return resultBuffer.call("addAll", argument);
    }

    private static Closure clearSyntax(final Collection<ValueSyntaxElement> toClear) {
        return Closure.wrap(
            toClear.stream().map(DatasetCompiler::clear).toArray(MethodLevelSyntaxElement[]::new)
        );
    }

    private static DatasetCompiler.ComputeAndClear computeAndClear(final Closure compute, final Closure clear,
        final ClassFields fields) {
        return new DatasetCompiler.ComputeAndClear(compute, clear, fields);
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
        public Collection<JrubyEventExtLibrary.RubyEvent> compute(@SuppressWarnings("rawtypes") final RubyArray batch,
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
            if (done) {
                parent.clear();
                done = false;
            }
        }
    }

    /**
     * Represents the 3-tuple of {@code compute} method, {@code clear} method and
     * {@link ClassFields} used by both methods.
     */
    private static final class ComputeAndClear {

        private final MethodSyntaxElement compute;

        private final MethodSyntaxElement clear;

        private final ClassFields fields;

        private ComputeAndClear(final Closure compute, final Closure clear,
            final ClassFields fields) {
            this.compute = MethodSyntaxElement.compute(compute);
            this.clear = MethodSyntaxElement.clear(clear);
            this.fields = fields;
        }

        public MethodSyntaxElement compute() {
            return compute;
        }

        public MethodSyntaxElement clear() {
            return clear;
        }

        public ClassFields fields() {
            return fields;
        }
    }
}
