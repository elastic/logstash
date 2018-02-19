package org.logstash.execution;

import java.util.concurrent.BlockingQueue;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.LongAdder;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.config.ir.CompiledPipeline;
import org.logstash.config.ir.compiler.Dataset;

public final class WorkerLoop implements Runnable {

    private static final Logger LOGGER = LogManager.getLogger(WorkerLoop.class);

    private final Dataset execution;

    private final BlockingQueue<IRubyObject> signalQueue;

    private final QueueReadClient readClient;

    private final AtomicBoolean flushing;

    private final LongAdder consumedCounter;

    private final LongAdder filteredCounter;

    private final boolean drainQueue;

    public WorkerLoop(final CompiledPipeline pipeline, final BlockingQueue<IRubyObject> signalQueue,
        final QueueReadClient readClient, final LongAdder filteredCounter,
        final LongAdder consumedCounter, final AtomicBoolean flushing, final boolean drainQueue) {
        this.consumedCounter = consumedCounter;
        this.filteredCounter = filteredCounter;
        this.execution = pipeline.buildExecution();
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
                final QueueBatch batch = readClient.readBatch();
                consumedCounter.add(batch.filteredSize());
                final boolean isFlush = signal != null && signal.callMethod(context, "flush?").isTrue();
                readClient.startMetrics(batch);
                execution.compute(batch.to_a(), isFlush, false);
                int filteredCount = batch.filteredSize();
                filteredCounter.add(filteredCount);
                readClient.addOutputMetrics(filteredCount);
                readClient.addFilteredMetrics(filteredCount);
                readClient.closeBatch(batch);
                if (isFlush) {
                    flushing.set(false);
                }
            } while (!shutdownRequested || isDraining());
            //we are shutting down, queue is drained if it was required, now  perform a final flush.
            //for this we need to create a new empty batch to contain the final flushed events
            final QueueBatch batch = readClient.newBatch();
            readClient.startMetrics(batch);
            execution.compute(batch.to_a(), true, false);
            readClient.closeBatch(batch);
        } catch (final Exception ex) {
            LOGGER.error(
                "Exception in pipelineworker, the pipeline stopped processing new events, please check your filter configuration and restart Logstash.",
                ex
            );
            throw new IllegalStateException(ex);
        }
    }

    private boolean isDraining() {
        return drainQueue && !readClient.isEmpty();
    }
}
