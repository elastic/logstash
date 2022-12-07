package org.logstash.execution;

import org.logstash.config.ir.CompiledPipeline;

class ObservedExecution<QB extends QueueBatch> implements CompiledPipeline.Execution<QB> {
    private final WorkerObserver workerObserver;
    private final CompiledPipeline.Execution<QB> execution;

    public ObservedExecution(final WorkerObserver workerObserver,
                             final CompiledPipeline.Execution<QB> execution) {
        this.workerObserver = workerObserver;
        this.execution = execution;
    }

    @Override
    public int compute(QB batch, boolean flush, boolean shutdown) {
        return workerObserver.observeExecutionComputation(batch, () -> execution.compute(batch, flush, shutdown));
    }
}
