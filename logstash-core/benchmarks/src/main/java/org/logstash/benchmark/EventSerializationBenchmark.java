package org.logstash.benchmark;

import java.io.DataOutputStream;
import java.util.HashMap;
import java.util.Map;
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
import org.openjdk.jmh.util.NullOutputStream;

@Warmup(iterations = 3, time = 500, timeUnit = TimeUnit.MILLISECONDS)
@Measurement(iterations = 10, time = 500, timeUnit = TimeUnit.MILLISECONDS)
@Fork(1)
@BenchmarkMode(Mode.Throughput)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Thread)
public class EventSerializationBenchmark {

    private static final int EVENTS_PER_INVOCATION = 10_000;

    private static final DataOutputStream SINK = new DataOutputStream(new NullOutputStream());

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
    public final void serializeCbor() throws Exception {
        for (int i = 0; i < EVENTS_PER_INVOCATION; ++i) {
            SINK.write(EVENT.serialize());
        }
    }

    @Benchmark
    @OperationsPerInvocation(EVENTS_PER_INVOCATION)
    public final void serializeJson() throws Exception {
        for (int i = 0; i < EVENTS_PER_INVOCATION; ++i) {
            SINK.writeBytes(EVENT.toJson());
        }
    }
}
