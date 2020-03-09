package org.logstash.execution;

import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.LongAdder;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.RubyArray;
import org.jruby.runtime.ThreadContext;
import org.logstash.RubyUtil;
import org.logstash.config.ir.CompiledPipeline;
import org.logstash.config.ir.compiler.Dataset;

public final class WorkerLoop implements Runnable {

    private static final Logger LOGGER = LogManager.getLogger(WorkerLoop.class);

    private final Dataset execution;

    private final QueueReadClient readClient;

    private final AtomicBoolean flushRequested;

    private final AtomicBoolean flushing;

    private final AtomicBoolean shutdownRequested;

    private final LongAdder consumedCounter;

    private final LongAdder filteredCounter;

    private final boolean drainQueue;

    private final boolean preserveEventOrder;

    public WorkerLoop(
        final CompiledPipeline pipeline,
        final QueueReadClient readClient,
        final LongAdder filteredCounter,
        final LongAdder consumedCounter,
        final AtomicBoolean flushRequested,
        final AtomicBoolean flushing,
        final AtomicBoolean shutdownRequested,
        final boolean drainQueue,
        final boolean preserveEventOrder)
    {
        this.consumedCounter = consumedCounter;
        this.filteredCounter = filteredCounter;
        this.execution = pipeline.buildExecution();
        this.drainQueue = drainQueue;
        this.readClient = readClient;
        this.flushRequested = flushRequested;
        this.flushing = flushing;
        this.shutdownRequested = shutdownRequested;
        this.preserveEventOrder = preserveEventOrder;
    }

    @Override
    public void run() {
        try {
            boolean isShutdown = false;
            do {
                isShutdown = isShutdown || shutdownRequested.get();
                final QueueBatch batch = readClient.readBatch();
                consumedCounter.add(batch.filteredSize());
                final boolean isFlush = flushRequested.compareAndSet(true, false);
                readClient.startMetrics(batch);
                compute(batch, isFlush, false);
                int filteredCount = batch.filteredSize();
                filteredCounter.add(filteredCount);
                readClient.addOutputMetrics(filteredCount);
                readClient.addFilteredMetrics(filteredCount);
                readClient.closeBatch(batch);
                if (isFlush) {
                    flushing.set(false);
                }
            } while (!isShutdown || isDraining());
            //we are shutting down, queue is drained if it was required, now  perform a final flush.
            //for this we need to create a new empty batch to contain the final flushed events
            final QueueBatch batch = readClient.newBatch();
            readClient.startMetrics(batch);
            compute(batch, true, true);
            readClient.closeBatch(batch);
        } catch (final Exception ex) {
            LOGGER.error(
                "Exception in pipelineworker, the pipeline stopped processing new events, please check your filter configuration and restart Logstash.",
                ex
            );
            throw new IllegalStateException(ex);
        }
    }

    @SuppressWarnings("unchecked")
    private void compute(final QueueBatch batch, final boolean flush, final boolean shutdown) {
        if (preserveEventOrder) {
            // send batch events one-by-one as single-element batches
            @SuppressWarnings({"rawtypes"}) final RubyArray singleElementBatch = RubyUtil.RUBY.newArray(1);
            batch.to_a().forEach((e) -> {
                singleElementBatch.set(0, e);
                execution.compute(singleElementBatch, flush, shutdown);
            });
        } else {
            execution.compute(batch.to_a(), flush, shutdown);
        }
    }

    private boolean isDraining() {
        return drainQueue && !readClient.isEmpty();
    }
}
