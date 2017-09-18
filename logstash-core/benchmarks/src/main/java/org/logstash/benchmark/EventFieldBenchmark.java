package org.logstash.benchmark;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import org.logstash.Event;
import org.logstash.FieldReference;
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
import org.openjdk.jmh.runner.Runner;
import org.openjdk.jmh.runner.RunnerException;
import org.openjdk.jmh.runner.options.Options;
import org.openjdk.jmh.runner.options.OptionsBuilder;

@Warmup(iterations = 3, time = 500, timeUnit = TimeUnit.MILLISECONDS)
@Measurement(iterations = 10, time = 500, timeUnit = TimeUnit.MILLISECONDS)
@Fork(1)
@BenchmarkMode(Mode.Throughput)
@OutputTimeUnit(TimeUnit.MICROSECONDS)
@State(Scope.Thread)
public class EventFieldBenchmark {

    private static final int EVENTS_PER_INVOCATION = 100_000;

    private static final Event EVENT = new Event();

    @Setup
    public void setUp() {
        EVENT.setField("Foo", "Bar");
        EVENT.setField("Foo1", "Bar1");
        EVENT.setField("Foo2", "Bar2");
        EVENT.setField("Foo3", "Bar3");
        EVENT.setField("Foo4", "Bar4");
        EVENT.setField("Foo5", new Timestamp(System.currentTimeMillis()));
        final Map<String, Object> nested = new HashMap<>(5);
        nested.put("foooo", "baaaaaar");
        nested.put("fooooish", "baaaaaar234");
        EVENT.setField("sdfsfsdf", nested);
        EVENT.setTimestamp(Timestamp.now());
    }

    @Benchmark
    @OperationsPerInvocation(EVENTS_PER_INVOCATION)
    public final void setByString() {
        for (int i = 0; i < EVENTS_PER_INVOCATION; ++i) {
            EVENT.setField("foo", "bar");
        }
    }

    @Benchmark
    @OperationsPerInvocation(EVENTS_PER_INVOCATION)
    public final void setByFieldRef() {
        final FieldReference field = FieldReference.from("foo");
        for (int i = 0; i < EVENTS_PER_INVOCATION; ++i) {
            EVENT.setField(field, "bar");
        }
    }

    public static void main(final String... args) throws RunnerException {
        Options opt = new OptionsBuilder()
            .include(EventFieldBenchmark.class.getSimpleName())
            .forks(2)
            .build();
        new Runner(opt).run();
    }
}
