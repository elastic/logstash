package org.logstash.execution;

import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.LongAdder;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.runtime.ThreadContext;
import org.logstash.RubyUtil;
import org.logstash.config.ir.CompiledPipeline;
import org.logstash.config.ir.compiler.Dataset;

public final class WorkerLoop implements Runnable {

    /**
     * Hard Reference to the Ruby {@link ThreadContext} for this thread. It is ok to keep
     * a hard reference instead of Ruby's weak references here since we can expect worker threads
     * to be runnable most of the time.
     */
    public static final ThreadLocal<ThreadContext> THREAD_CONTEXT =
        ThreadLocal.withInitial(RubyUtil.RUBY::getCurrentContext);

    private static final Logger LOGGER = LogManager.getLogger(WorkerLoop.class);

    private final Dataset execution;

    private final QueueReadClient readClient;

    private final AtomicBoolean flushRequested;

    private final AtomicBoolean flushing;

    private final AtomicBoolean shutdownRequested;

    private final LongAdder consumedCounter;

    private final LongAdder filteredCounter;

    private final boolean drainQueue;

    public WorkerLoop(final CompiledPipeline pipeline, final QueueReadClient readClient,
        final LongAdder filteredCounter, final LongAdder consumedCounter,
        final AtomicBoolean flushRequested, final AtomicBoolean flushing,
        final AtomicBoolean shutdownRequested, final boolean drainQueue) {
        this.consumedCounter = consumedCounter;
        this.filteredCounter = filteredCounter;
        this.execution = pipeline.buildExecution();
        this.drainQueue = drainQueue;
        this.readClient = readClient;
        this.flushRequested = flushRequested;
        this.flushing = flushing;
        this.shutdownRequested = shutdownRequested;
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
                execution.compute(batch.to_a(), isFlush, false);
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
            execution.compute(batch.to_a(), true, true);
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
