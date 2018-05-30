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

@JRubyClass(name = "ShutdownWatcher")
public final class ShutdownWatcherExt extends RubyBasicObject {

    private static final Logger LOGGER = LogManager.getLogger(ShutdownWatcherExt.class);

    private static final AtomicBoolean unsafeShutdown = new AtomicBoolean(false);

    private final List<IRubyObject> reports = new ArrayList<>();

    private final AtomicInteger attemptsCount = new AtomicInteger(0);

    private final AtomicBoolean running = new AtomicBoolean(false);

    private long cyclePeriod = 1L;

    private int reportEvery = 5;

    private int abortThreshold = 3;

    private IRubyObject pipeline;

    @JRubyMethod(meta = true, required = 1, optional = 3)
    public static RubyThread start(final ThreadContext context, final IRubyObject recv, final IRubyObject[] args) {
        return new RubyThread(context.runtime, context.runtime.getThread(), () -> {
            try {
                new ShutdownWatcherExt(context.runtime, RubyUtil.SHUTDOWN_WATCHER_CLASS)
                    .initialize(context, args).start(context);
            } catch (final InterruptedException ex) {
                throw new IllegalStateException(ex);
            }
        });
    }

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
                if (stopped(context).isTrue() ||
                    !pipeline.callMethod(context, "thread")
                        .callMethod(context, "alive?").isTrue()) {
                    break;
                }
                reports.add(pipelineReportSnapshot(context));
                if (reports.size() > reportEvery) {
                    reports.remove(0);
                }
                if (cycleNumber == reportEvery - 1) {
                    LOGGER.warn(reports.get(reports.size() - 1).callMethod(context, "to_s")
                        .asJavaString());
                    if (shutdownStalled(context).isTrue()) {
                        if (stalledCount == 0) {
                            LOGGER.error(
                                "The shutdown process appears to be stalled due to busy or blocked plugins. Check the logs for more information."
                            );
                        }
                        ++stalledCount;
                        if (isUnsafeShutdown(context, null).isTrue() &&
                            abortThreshold == stalledCount) {
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
