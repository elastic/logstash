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

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.Ruby;
import org.jruby.RubyBasicObject;
import org.jruby.RubyClass;
import org.jruby.RubyThread;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;

/**
 * JRuby extension, used by pipelines to execute the shutdown flow of a pipeline.
 * */
@JRubyClass(name = "ShutdownWatcher")
public final class ShutdownWatcherExt extends RubyBasicObject {

    private static final long serialVersionUID = 1L;

    private static final Logger LOGGER = LogManager.getLogger(ShutdownWatcherExt.class);

    private static final AtomicBoolean unsafeShutdown = new AtomicBoolean(false);

    private final transient List<IRubyObject> reports = new ArrayList<>();

    private final AtomicInteger attemptsCount = new AtomicInteger(0);

    private final AtomicBoolean running = new AtomicBoolean(false);

    private long cyclePeriod = 1L;

    private int reportEvery = 5;

    private int abortThreshold = 3;

    private transient IRubyObject pipeline;

    @JRubyMethod(name = "unsafe_shutdown?", meta = true)
    public static IRubyObject isUnsafeShutdown(final ThreadContext context,
        final IRubyObject recv) {
        return unsafeShutdown.get() ? context.tru : context.fals;
    }

    @JRubyMethod(name = "unsafe_shutdown=", meta = true)
    public static IRubyObject setUnsafeShutdown(final ThreadContext context,
        final IRubyObject recv, final IRubyObject arg) {
        unsafeShutdown.set(arg.isTrue());
        return context.nil;
    }

    public ShutdownWatcherExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(required = 1, optional = 3)
    public ShutdownWatcherExt initialize(final ThreadContext context, final IRubyObject[] args) {
        pipeline = args[0];
        if (args.length >= 2) {
            cyclePeriod = args[1].convertToInteger().getLongValue();
            if (args.length >= 3) {
                reportEvery = args[2].convertToInteger().getIntValue();
                if (args.length >= 4) {
                    abortThreshold = args[3].convertToInteger().getIntValue();
                }
            }
        }
        return this;
    }

    @JRubyMethod(name = "pipeline_report_snapshot")
    public IRubyObject pipelineReportSnapshot(final ThreadContext context) {
        return pipeline.callMethod(context, "reporter").callMethod(context, "snapshot");
    }

    @JRubyMethod(name = "shutdown_stalled?")
    public IRubyObject shutdownStalled(final ThreadContext context) {
        if (reports.size() != reportEvery) {
            return context.fals;
        }
        final int[] inflightCounts = reports.stream().mapToInt(
            obj -> obj.callMethod(context, "inflight_count").convertToInteger().getIntValue()
        ).toArray();
        boolean stalled = true;
        for (int i = 0; i < inflightCounts.length - 1; ++i) {
            if (inflightCounts[i] > inflightCounts[i + 1]) {
                stalled = false;
                break;
            }
        }
        if (stalled) {
            final IRubyObject[] stallingThreads = reports.stream().map(
                obj -> obj.callMethod(context, "stalling_threads")
            ).toArray(IRubyObject[]::new);
            for (int i = 0; i < stallingThreads.length - 1; ++i) {
                if (!stallingThreads[i].op_equal(context, stallingThreads[i + 1]).isTrue()) {
                    stalled = false;
                    break;
                }
            }
            return stalled ? context.tru : context.fals;
        }
        return context.fals;
    }

    @JRubyMethod(name = "stop!")
    public IRubyObject stop(final ThreadContext context) {
        return running.compareAndSet(true, false) ? context.tru : context.fals;
    }

    @JRubyMethod(name = "stopped?")
    public IRubyObject stopped(final ThreadContext context) {
        return running.get() ? context.fals : context.tru;
    }

    @JRubyMethod(name = "attempts_count")
    public IRubyObject attemptsCount(final ThreadContext context) {
        return context.runtime.newFixnum(attemptsCount.get());
    }

    @JRubyMethod
    public IRubyObject start(final ThreadContext context) throws InterruptedException {
        int cycleNumber = 0;
        int stalledCount = 0;
        running.set(true);
        try {
            while (true) {
                TimeUnit.SECONDS.sleep(cyclePeriod);
                attemptsCount.incrementAndGet();
                if (stopped(context).isTrue() || pipeline.callMethod(context, "finished_execution?").isTrue()) {
                    break;
                }
                reports.add(pipelineReportSnapshot(context));
                if (reports.size() > reportEvery) {
                    reports.remove(0);
                }
                if (cycleNumber == reportEvery - 1) {
                    boolean isPqDraining = pipeline.callMethod(context, "worker_threads_draining?").isTrue();

                    if (!isPqDraining) {
                        LOGGER.warn(reports.get(reports.size() - 1).callMethod(context, "to_s").asJavaString());
                    }

                    if (shutdownStalled(context).isTrue()) {
                        if (stalledCount == 0) {
                            LOGGER.error("The shutdown process appears to be stalled due to busy or blocked plugins. Check the logs for more information.");
                            if (isPqDraining) {
                                String pipelineId = pipeline.callMethod(context, "pipeline_id").asJavaString();
                                LOGGER.info("The queue for pipeline {} is draining before shutdown.", pipelineId);
                            }
                        }
                        ++stalledCount;
                        if (isUnsafeShutdown(context, null).isTrue() && abortThreshold == stalledCount) {
                            LOGGER.fatal("Forcefully quitting Logstash ...");
                            forceExit(context);
                        }
                    } else {
                        stalledCount = 0;
                    }
                }
                cycleNumber = (cycleNumber + 1) % reportEvery;
            }
            return context.nil;
        } finally {
            stop(context);
        }
    }

    @JRubyMethod(name = "cycle_period")
    public IRubyObject cyclePeriod(final ThreadContext context) {
        return context.runtime.newFixnum(cyclePeriod);
    }

    @JRubyMethod(name = "report_every")
    public IRubyObject reportEvery(final ThreadContext context) {
        return context.runtime.newFixnum(reportEvery);
    }

    @JRubyMethod(name = "abort_threshold")
    public IRubyObject abortThreshold(final ThreadContext context) {
        return context.runtime.newFixnum(abortThreshold);
    }

    @JRubyMethod(name = "force_exit")
    public IRubyObject forceExit(final ThreadContext context) {
        throw context.runtime.newSystemExit(-1);
    }
}
