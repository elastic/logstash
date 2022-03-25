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

import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.LongAdder;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.config.ir.CompiledPipeline;

/**
 * Pipeline execution worker, it's responsible to execute filters and output plugins for each {@link QueueBatch} that
 * pull out from queue.
 * */
public final class WorkerLoop implements Runnable {

    private static final Logger LOGGER = LogManager.getLogger(WorkerLoop.class);

    private final CompiledPipeline.CompiledExecution execution;

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
        this.execution = pipeline.buildExecution(preserveEventOrder);
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
                final boolean isFlush = flushRequested.compareAndSet(true, false);
                if (batch.filteredSize() > 0 || isFlush) {
                    consumedCounter.add(batch.filteredSize());
                    readClient.startMetrics(batch);
                    final int outputCount = execution.compute(batch, isFlush, false);
                    int filteredCount = batch.filteredSize();
                    filteredCounter.add(filteredCount);
                    readClient.addOutputMetrics(outputCount);
                    readClient.addFilteredMetrics(filteredCount);
                    readClient.closeBatch(batch);
                    if (isFlush) {
                        flushing.set(false);
                    }
                }
            } while (!isShutdown || isDraining());
            //we are shutting down, queue is drained if it was required, now  perform a final flush.
            //for this we need to create a new empty batch to contain the final flushed events
            final QueueBatch batch = readClient.newBatch();
            readClient.startMetrics(batch);
            execution.compute(batch, true, true);
            readClient.closeBatch(batch);
        } catch (final Exception ex) {
            throw new IllegalStateException(ex);
        }
    }

    public boolean isDraining() {
        return drainQueue && !readClient.isEmpty();
    }
}
