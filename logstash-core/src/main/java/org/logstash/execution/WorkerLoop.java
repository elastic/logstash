package org.logstash.execution;

import java.util.concurrent.BlockingQueue;
import java.util.concurrent.atomic.AtomicBoolean;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.RubyArray;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.config.ir.compiler.Dataset;

public final class WorkerLoop implements Runnable {

    private static final Logger LOGGER = LogManager.getLogger(WorkerLoop.class);

    private final Dataset execution;

    private final BlockingQueue<IRubyObject> signalQueue;

    private final IRubyObject readClient;

    private final AtomicBoolean flushing;

    private final IRubyObject consumedCounter;

    private final IRubyObject filteredCounter;

    private final boolean drainQueue;

    public WorkerLoop(final Dataset execution, final BlockingQueue<IRubyObject> signalQueue,
        final IRubyObject readClient, final IRubyObject filteredCounter,
        final IRubyObject consumedCounter, final AtomicBoolean flushing, final boolean drainQueue) {
        this.consumedCounter = consumedCounter;
        this.filteredCounter = filteredCounter;
        this.execution = execution;
        this.signalQueue = signalQueue;
        this.drainQueue = drainQueue;
        this.readClient = readClient;
        this.flushing = flushing;
    }

    @Override
    public void run() {
        try {
            boolean shutdownRequested = false;
            final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
            do {
                final IRubyObject signal = signalQueue.poll();
                shutdownRequested = shutdownRequested
                    || signal != null && signal.callMethod(context, "shutdown?").isTrue();
                final IRubyObject batch = readClient.callMethod(context, "read_batch");
                consumedCounter.callMethod(
                    context, "increment", batch.callMethod(context, "size")
                );
                final boolean isFlush = signal != null && signal.callMethod(context, "flush?").isTrue();
                readClient.callMethod(context, "start_metrics", batch);
                execution.compute((RubyArray) batch.callMethod(context, "to_a"), isFlush, false);
                filteredCounter.callMethod(
                    context, "increment", batch.callMethod(context, "size")
                );
                final IRubyObject filteredSize = batch.callMethod(context, "filtered_size");
                readClient.callMethod(context, "add_output_metrics", filteredSize);
                readClient.callMethod(context, "add_filtered_metrics", filteredSize);
                readClient.callMethod(context, "close_batch", batch);
                if (isFlush) {
                    flushing.set(false);
                }
            } while (!shutdownRequested && !isDraining(context));
            //we are shutting down, queue is drained if it was required, now  perform a final flush.
            //for this we need to create a new empty batch to contain the final flushed events
            final IRubyObject batch = readClient.callMethod(context, "new_batch");
            readClient.callMethod(context, "start_metrics", batch);
            execution.compute((RubyArray) batch.callMethod(context, "to_a"), true, false);
            readClient.callMethod(context, "close_batch", batch);
        } catch (final Exception ex) {
            LOGGER.error(
                "Exception in pipelineworker, the pipeline stopped processing new events, please check your filter configuration and restart Logstash.",
                ex
            );
            throw new IllegalStateException(ex);
        }
    }

    private boolean isDraining(final ThreadContext context) {
        return drainQueue && !readClient.callMethod(context, "empty?").isTrue();
    }
}
