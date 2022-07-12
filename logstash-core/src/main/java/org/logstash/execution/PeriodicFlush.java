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

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

@SuppressWarnings("try")
/**
 * Used by Ruby's JavaPipeline
 * */
public final class PeriodicFlush implements AutoCloseable {

    private static final Logger LOGGER = LogManager.getLogger(PeriodicFlush.class);

    private final ScheduledExecutorService executor = Executors.newSingleThreadScheduledExecutor(
        r -> new Thread(r, "logstash-pipeline-flush")
    );

    private final AtomicBoolean flushRequested;

    private final AtomicBoolean flushing;

    public PeriodicFlush(final AtomicBoolean flushRequested, final AtomicBoolean flushing) {
        this.flushRequested = flushRequested;
        this.flushing = flushing;
    }

    public void start() {
        executor.scheduleAtFixedRate(() -> {
            if (flushing.compareAndSet(false, true)) {
                LOGGER.debug("Pushing flush onto pipeline.");
                flushRequested.set(true);
            }
        }, 0L, 5L, TimeUnit.SECONDS);
    }

    @Override
    public void close() throws InterruptedException {
        executor.shutdown();
        if (!executor.awaitTermination(10L, TimeUnit.SECONDS)) {
            throw new IllegalStateException("Failed to stop period flush action.");
        }
    }
}
