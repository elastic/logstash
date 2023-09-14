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


package org.logstash.execution;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyBasicObject;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.RubyThread;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.config.ir.compiler.AbstractOutputDelegatorExt;

import java.util.Collection;
import java.util.Optional;

/**
 * JRuby extension
 * */
@JRubyClass(name = "PipelineReporter")
public final class PipelineReporterExt extends RubyBasicObject {

    private static final long serialVersionUID = 1L;

    private static final RubySymbol EVENTS_FILTERED_KEY =
        RubyUtil.RUBY.newSymbol("events_filtered");

    private static final RubySymbol EVENTS_CONSUMED_KEY =
        RubyUtil.RUBY.newSymbol("events_consumed");

    private static final RubySymbol INFLIGHT_COUNT_KEY =
        RubyUtil.RUBY.newSymbol("inflight_count");

    private static final RubySymbol WORKER_STATES_KEY =
        RubyUtil.RUBY.newSymbol("worker_states");

    private static final RubySymbol OUTPUT_INFO_KEY =
        RubyUtil.RUBY.newSymbol("output_info");

    private static final RubySymbol THREAD_INFO_KEY =
        RubyUtil.RUBY.newSymbol("thread_info");

    private static final RubySymbol STALLING_THREADS_INFO_KEY =
        RubyUtil.RUBY.newSymbol("stalling_threads_info");

    private static final RubySymbol TYPE_KEY = RubyUtil.RUBY.newSymbol("type");

    private static final RubySymbol ID_KEY = RubyUtil.RUBY.newSymbol("id");

    private static final RubySymbol STATUS_KEY = RubyUtil.RUBY.newSymbol("status");

    private static final RubySymbol ALIVE_KEY = RubyUtil.RUBY.newSymbol("alive");

    private static final RubySymbol INDEX_KEY = RubyUtil.RUBY.newSymbol("index");

    private static final RubySymbol CONCURRENCY_KEY = RubyUtil.RUBY.newSymbol("concurrency");

    private static final RubyString DEAD_STATUS =
        RubyUtil.RUBY.newString("dead").newFrozen();

    private transient IRubyObject logger;

    private transient IRubyObject pipeline;

    public PipelineReporterExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    public PipelineReporterExt initialize(final ThreadContext context, final IRubyObject logger,
        final IRubyObject pipeline) {
        this.logger = logger;
        this.pipeline = pipeline;
        return this;
    }

    @JRubyMethod
    public IRubyObject pipeline() {
        return pipeline;
    }

    @JRubyMethod
    public IRubyObject logger() {
        return logger;
    }

    /**
     * The main way of accessing data from the reporter,,
     * this provides a (more or less) consistent snapshot of what's going on in the
     * pipeline with some extra decoration
     * @param context Thread Context
     * @return Snapshot
     */
    @JRubyMethod
    public PipelineReporterExt.SnapshotExt snapshot(final ThreadContext context) {
        return new PipelineReporterExt.SnapshotExt(
            context.runtime, RubyUtil.PIPELINE_REPORTER_SNAPSHOT_CLASS).initialize(toHash(context)
        );
    }

    @JRubyMethod(name = "to_hash")
    public RubyHash toHash(final ThreadContext context) {
        final RubyHash result = RubyHash.newHash(context.runtime);
        final RubyHash batchMap = (RubyHash) pipeline
            .callMethod(context, "filter_queue_client")
            .callMethod(context, "inflight_batches");
        @SuppressWarnings("rawtypes")
        final RubyArray workerStates = workerStates(context, batchMap);
        result.op_aset(context, WORKER_STATES_KEY, workerStates);
        result.op_aset(
            context,
            EVENTS_FILTERED_KEY,
            pipeline.callMethod(context, "events_filtered").callMethod(context, "sum")
        );
        result.op_aset(
            context,
            EVENTS_CONSUMED_KEY,
            pipeline.callMethod(context, "events_consumed").callMethod(context, "sum")
        );
        result.op_aset(context, OUTPUT_INFO_KEY, outputInfo(context));
        result.op_aset(
            context, THREAD_INFO_KEY, pipeline.callMethod(context, "plugin_threads_info")
        );
        result.op_aset(
            context, STALLING_THREADS_INFO_KEY,
            pipeline.callMethod(context, "stalling_threads_info")
        );
        result.op_aset(
            context, INFLIGHT_COUNT_KEY,
            context.runtime.newFixnum(calcInflightCount(context, workerStates))
        );
        return result;
    }

    @SuppressWarnings({"unchecked","rawtypes"})
    private RubyArray workerStates(final ThreadContext context, final RubyHash batchMap) {
        final RubyArray result = context.runtime.newArray();
        ((Iterable<IRubyObject>) pipeline.callMethod(context, "worker_threads"))
            .forEach(thread -> {

                final RubyHash hash = RubyHash.newHash(context.runtime);
                IRubyObject status = thread.callMethod(context, "status");
                if (status.isNil()) {
                    status = DEAD_STATUS;
                }
                hash.op_aset(context, STATUS_KEY, status);
                hash.op_aset(context, ALIVE_KEY, thread.callMethod(context, "alive?"));
                hash.op_aset(context, INDEX_KEY, context.runtime.newFixnum(result.size()));

                IRubyObject batchSize = Optional.of((RubyThread) thread)
                        .map(RubyThread::getNativeThread)
                        .map(Thread::getId)
                        .map(id -> batchMap.op_aref(context, context.runtime.newFixnum(id)))
                        .map(batch -> extractBatchSize(context, batch))
                        .orElse(context.runtime.newFixnum(0L));

                hash.op_aset(context, INFLIGHT_COUNT_KEY, batchSize);
                result.add(hash);
            });
        return result;
    }

    /**
     * Attempts to safely extract the batch size from a wrapped {@link QueueBatch} or
     * a ruby object responding to {@code size}
     *
     * @param context The Ruby {@code ThreadContext}
     * @param batch a batch, which may be a wrapped {@link QueueBatch} or a ruby
     *              object that responds to `#size`
     * @return the detected size, or zero.
     */
    private IRubyObject extractBatchSize(final ThreadContext context, final IRubyObject batch) {
        if (!batch.isNil()) {
            if (QueueBatch.class.isAssignableFrom(batch.getJavaClass())) {
                final int filteredSize = batch.toJava(QueueBatch.class).filteredSize();
                return getRuntime().newFixnum(filteredSize);
            }
            if (batch.respondsTo("size")) {
                return batch.callMethod(context, "size");
            }
        }
        return context.runtime.newFixnum(0L);
    }

    @SuppressWarnings({"unchecked","rawtypes"})
    private RubyArray outputInfo(final ThreadContext context) {
        final RubyArray result = context.runtime.newArray();
        final IRubyObject outputs = pipeline.callMethod(context, "outputs");
        final Iterable<IRubyObject> outputIterable;
        if (outputs instanceof Iterable) {
            outputIterable = (Iterable<IRubyObject>) outputs;
        } else {
            outputIterable = (Iterable<IRubyObject>) outputs.toJava(Iterable.class);
        }
        outputIterable.forEach(output -> {
            final AbstractOutputDelegatorExt delegator = (AbstractOutputDelegatorExt) output;
            final RubyHash hash = RubyHash.newHash(context.runtime);
            hash.op_aset(context, TYPE_KEY, delegator.configName(context));
            hash.op_aset(context, ID_KEY, delegator.getId());
            hash.op_aset(context, CONCURRENCY_KEY, delegator.concurrency(context));
            result.add(hash);
        });
        return result;
    }

    @SuppressWarnings("unchecked")
    private static int calcInflightCount(final ThreadContext context,
        final Collection<?> workerStates) {
        return workerStates.stream().mapToInt(
            state -> ((RubyHash) state).op_aref(context, INFLIGHT_COUNT_KEY)
                .convertToInteger().getIntValue()
        ).sum();
    }

    /**
     * This is an immutable copy of the pipeline state,
     * It is a proxy to a hash to allow us to add methods dynamically to the hash.
     */
    @JRubyClass(name = "Snapshot")
    public static final class SnapshotExt extends RubyBasicObject {

        private static final long serialVersionUID = 1L;

        private static final RubyString INFLIGHT_COUNT_KEY =
            RubyUtil.RUBY.newString("inflight_count").newFrozen();

        private static final RubyString STALLING_THREADS_KEY =
            RubyUtil.RUBY.newString("stalling_threads_info").newFrozen();

        private static final RubyString PLUGIN_KEY =
            RubyUtil.RUBY.newString("plugin").newFrozen();

        private static final RubyString OTHER_KEY =
            RubyUtil.RUBY.newString("other").newFrozen();

        private RubyHash data;

        public SnapshotExt(final Ruby runtime, final RubyClass metaClass) {
            super(runtime, metaClass);
        }

        @JRubyMethod
        public PipelineReporterExt.SnapshotExt initialize(final IRubyObject data) {
            this.data = (RubyHash) data;
            return this;
        }

        @JRubyMethod(name = "to_hash")
        public RubyHash toHash() {
            return data;
        }

        @JRubyMethod(name = "to_simple_hash")
        public RubyHash toSimpleHash(final ThreadContext context) {
            final RubyHash result = RubyHash.newHash(context.runtime);
            result.op_aset(
                context, INFLIGHT_COUNT_KEY, data.op_aref(context, INFLIGHT_COUNT_KEY.intern())
            );
            result.op_aset(context, STALLING_THREADS_KEY, formatThreadsByPlugin(context));
            return result;
        }

        @JRubyMethod(name = {"to_s", "to_str"})
        public RubyString toStr(final ThreadContext context) {
            return (RubyString) toSimpleHash(context).to_s(context);
        }

        @JRubyMethod(name = "method_missing")
        public IRubyObject methodMissing(final ThreadContext context, final IRubyObject method) {
            return data.op_aref(context, method);
        }

        @JRubyMethod(name = "respond_to_missing?")
        public IRubyObject isRespondToMissing(final ThreadContext context, final IRubyObject method, final IRubyObject includePrivate) {
            return context.tru;
        }

        @JRubyMethod(name = "format_threads_by_plugin")
        @SuppressWarnings("unchecked")
        public RubyHash formatThreadsByPlugin(final ThreadContext context) {
            final RubyHash result = RubyHash.newHash(context.runtime);
            ((Iterable<?>) data.get(STALLING_THREADS_KEY.intern())).forEach(thr -> {
                final RubyHash threadInfo = (RubyHash) thr;
                IRubyObject key = threadInfo.delete(context, PLUGIN_KEY, Block.NULL_BLOCK);
                if (key.isNil()) {
                    key = OTHER_KEY;
                }
                if (result.op_aref(context, key).isNil()) {
                    result.op_aset(context, key, context.runtime.newArray());
                }
                ((RubyArray) result.op_aref(context, key)).append(threadInfo);
            });
            return result;
        }
    }
}
