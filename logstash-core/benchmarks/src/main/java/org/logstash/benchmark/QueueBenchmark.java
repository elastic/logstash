package org.logstash.benchmark;

import com.google.common.io.Files;
import java.io.File;
import java.io.IOException;
import java.util.concurrent.TimeUnit;
import org.apache.commons.io.FileUtils;
import org.logstash.Event;
import org.logstash.Timestamp;
import org.logstash.ackedqueue.Queue;
import org.logstash.ackedqueue.Settings;
import org.logstash.ackedqueue.SettingsImpl;
import org.logstash.ackedqueue.io.FileCheckpointIO;
import org.logstash.ackedqueue.io.MmapPageIO;
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
import org.openjdk.jmh.runner.Runner;
import org.openjdk.jmh.runner.RunnerException;
import org.openjdk.jmh.runner.options.Options;
import org.openjdk.jmh.runner.options.OptionsBuilder;

@Warmup(iterations = 3, time = 100, timeUnit = TimeUnit.MILLISECONDS)
@Measurement(iterations = 10, time = 100, timeUnit = TimeUnit.MILLISECONDS)
@Fork(1)
@BenchmarkMode(Mode.Throughput)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Thread)
public class QueueBenchmark {

    private static final int EVENTS_PER_INVOCATION = 500_000;

    private static final Event EVENT = new Event();

    private Queue queue;

    private String path;

    @Setup
    public void setUp() throws IOException {
        final Settings settings = settings();
        EVENT.setField("Foo", "Bar");
        EVENT.setField("Foo1", "Bar1");
        EVENT.setField("Foo2", "Bar2");
        EVENT.setField("Foo3", "Bar3");
        EVENT.setField("Foo4", "Bar4");
        path = settings.getDirPath();
        queue = new Queue(settings);
        queue.open();
    }

    @TearDown
    public void tearDown() throws IOException {
        queue.close();
        FileUtils.deleteDirectory(new File(path));
    }

    @Benchmark
    @OperationsPerInvocation(EVENTS_PER_INVOCATION)
    public final void pushToPersistedQueue() throws Exception {
        for (int i = 0; i < EVENTS_PER_INVOCATION; ++i) {
            final Event evnt = EVENT.clone();
            evnt.setTimestamp(Timestamp.now());
            queue.write(evnt);
        }
    }

    public static void main(final String... args) throws RunnerException {
        Options opt = new OptionsBuilder()
            .include(QueueBenchmark.class.getSimpleName())
            .forks(2)
            .build();
        new Runner(opt).run();
    }

    private static Settings settings() {
        return SettingsImpl.fileSettingsBuilder(Files.createTempDir().getPath())
            .capacity(256 * 1024 * 1024)
            .queueMaxBytes(Long.MAX_VALUE)
            .elementIOFactory(MmapPageIO::new)
            .checkpointMaxWrites(1024)
            .checkpointMaxAcks(1024)
            .checkpointIOFactory(FileCheckpointIO::new)
            .elementClass(Event.class).build();
    }
}
