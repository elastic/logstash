package org.logstash.benchmark;

import java.io.IOException;
import java.util.concurrent.TimeUnit;
import org.logstash.Event;
import org.logstash.Timestamp;
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
import org.openjdk.jmh.annotations.Warmup;
import org.openjdk.jmh.infra.Blackhole;
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
public class EventSprintfBenchmark {

    private static final int EVENTS_PER_INVOCATION = 10_000_000;

    private static final Event EVENT = new Event();

    @Setup
    public void setUp() throws IOException {
        EVENT.setField("Foo", "Bar");
        EVENT.setField("Foo1", "Bar1");
        EVENT.setField("Foo2", "Bar2");
        EVENT.setField("Foo3", "Bar3");
        EVENT.setField("Foo4", "Bar4");
        EVENT.setTimestamp(Timestamp.now());
    }

    @Benchmark
    @OperationsPerInvocation(EVENTS_PER_INVOCATION)
    public final void sprintfField(final Blackhole blackhole) throws Exception {
        for (int i = 0; i < EVENTS_PER_INVOCATION; ++i) {
            blackhole.consume(EVENT.sprintf(i + "-%{[Foo]}"));
        }
    }

    public static void main(final String... args) throws RunnerException {
        Options opt = new OptionsBuilder()
            .include(EventSprintfBenchmark.class.getSimpleName())
            .forks(2)
            .build();
        new Runner(opt).run();
    }
}
