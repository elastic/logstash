package org.logstash.execution;

import org.logstash.config.ir.CompiledPipeline;

class ObservedExecution implements CompiledPipeline.Execution {
    private final WorkerObserver workerObserver;
    private final CompiledPipeline.Execution execution;

    public ObservedExecution(final WorkerObserver workerObserver,
                             final CompiledPipeline.Execution execution) {
        this.workerObserver = workerObserver;
        this.execution = execution;
    }

    @Override
    public int compute(QueueBatch batch, boolean flush, boolean shutdown) {
        return workerObserver.observeExecutionComputation(batch, () -> execution.compute(batch, flush, shutdown));
    }
}
