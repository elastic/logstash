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


package org.logstash.benchmark;

import com.google.common.io.Files;
import java.io.File;
import java.io.IOException;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import org.apache.commons.io.FileUtils;
import org.logstash.Event;
import org.logstash.ackedqueue.Batch;
import org.logstash.ackedqueue.Queue;
import org.logstash.ackedqueue.Queueable;
import org.logstash.ackedqueue.Settings;
import org.logstash.ackedqueue.SettingsImpl;
import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.BenchmarkMode;
import org.openjdk.jmh.annotations.Fork;
import org.openjdk.jmh.annotations.Measurement;
import org.openjdk.jmh.annotations.Mode;
import org.openjdk.jmh.annotations.OperationsPerInvocation;
import org.openjdk.jmh.annotations.OutputTimeUnit;
import org.openjdk.jmh.annotations.Scope;
import org.openjdk.jmh.annotations.Setup;
import org.openjdk.jmh.annotations.State;
import org.openjdk.jmh.annotations.TearDown;
import org.openjdk.jmh.annotations.Warmup;
import org.openjdk.jmh.infra.Blackhole;

@Warmup(iterations = 3, time = 100, timeUnit = TimeUnit.MILLISECONDS)
@Measurement(iterations = 10, time = 100, timeUnit = TimeUnit.MILLISECONDS)
@Fork(1)
@BenchmarkMode(Mode.Throughput)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Thread)
public class QueueRWBenchmark {

    private static final int EVENTS_PER_INVOCATION = 500_000;

    private static final int BATCH_SIZE = 100;

    private static final int ACK_INTERVAL = 1024;

    private static final Event EVENT = new Event();

    private ArrayBlockingQueue<Event> queueArrayBlocking;

    private Queue queuePersisted;

    private String path;

    private ExecutorService exec;

    @Setup
    public void setUp() throws IOException {
        final Settings settingsPersisted = settings();
        EVENT.setField("Foo", "Bar");
        EVENT.setField("Foo1", "Bar1");
        EVENT.setField("Foo2", "Bar2");
        EVENT.setField("Foo3", "Bar3");
        EVENT.setField("Foo4", "Bar4");
        path = settingsPersisted.getDirPath();
        queuePersisted = new Queue(settingsPersisted);
        queueArrayBlocking = new ArrayBlockingQueue<>(ACK_INTERVAL);
        queuePersisted.open();
        exec = Executors.newSingleThreadExecutor();
    }

    @TearDown
    public void tearDown() throws IOException {
        queuePersisted.close();
        queueArrayBlocking.clear();
        FileUtils.deleteDirectory(new File(path));
        exec.shutdownNow();
    }

    @Benchmark
    @OperationsPerInvocation(EVENTS_PER_INVOCATION)
    public final void readFromPersistedQueue(final Blackhole blackhole) throws Exception {
        final Future<?> future = exec.submit(() -> {
            for (int i = 0; i < EVENTS_PER_INVOCATION; ++i) {
                try {
                    this.queuePersisted.write(EVENT);
                } catch (final IOException ex) {
                    throw new IllegalStateException(ex);
                }
            }
        });
        for (int i = 0; i < EVENTS_PER_INVOCATION / BATCH_SIZE; ++i) {
            try (Batch batch = queuePersisted.readBatch(BATCH_SIZE, TimeUnit.SECONDS.toMillis(1))) {
                for (final Queueable elem : batch.getElements()) {
                    blackhole.consume(elem);
                }
            }
        }
        future.get();
    }

    @Benchmark
    @OperationsPerInvocation(EVENTS_PER_INVOCATION)
    public final void readFromArrayBlockingQueue(final Blackhole blackhole) throws Exception {
        final Future<?> future = exec.submit(() -> {
            for (int i = 0; i < EVENTS_PER_INVOCATION; ++i) {
                try {
                    queueArrayBlocking.put(EVENT);
                } catch (final InterruptedException ex) {
                    throw new IllegalStateException(ex);
                }
            }
        });
        for (int i = 0; i < EVENTS_PER_INVOCATION; ++i) {
            blackhole.consume(queueArrayBlocking.take());
        }
        future.get();
    }

    private static Settings settings() {
        return SettingsImpl.fileSettingsBuilder(Files.createTempDir().getPath())
            .capacity(256 * 1024 * 1024)
            .queueMaxBytes(Long.MAX_VALUE)
            .checkpointMaxWrites(ACK_INTERVAL)
            .checkpointMaxAcks(ACK_INTERVAL)
            .elementClass(Event.class).build();
    }
}
