package org.logstash.benchmark;

import com.fasterxml.jackson.core.JsonProcessingException;
import org.jruby.java.proxies.ConcreteJavaProxy;
import org.logstash.Event;
import org.logstash.RubyUtil;
import org.logstash.Timestamp;
import org.openjdk.jmh.annotations.*;
import org.openjdk.jmh.infra.Blackhole;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/*
* ./gradlew jmh -Pinclude="org.logstash.benchmark.EventSizeEstimationBenchmark.*"
* */

@Warmup(iterations = 3, time = 100, timeUnit = TimeUnit.MILLISECONDS)
@Measurement(iterations = 10, time = 100, timeUnit = TimeUnit.MILLISECONDS)
@Fork(1)
@BenchmarkMode(Mode.Throughput)
@OutputTimeUnit(TimeUnit.SECONDS)
@State(Scope.Thread)
public class EventSizeEstimationBenchmark {

    // 512 bytes
    public static final String MEDIUM_FILLING_STRING = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum Excepteur sint occaecat cupidatat non proident, sunt in culpa quioe";

    //2048 bytes
    public static final String LONG_FILLING_STRING = MEDIUM_FILLING_STRING + MEDIUM_FILLING_STRING + MEDIUM_FILLING_STRING + MEDIUM_FILLING_STRING;
    private Event mediumEvent;
    private Event longEvent;
    private Event longEvent_1_nestingLevel;

    @Setup(Level.Invocation)
    public void setUp() {
        mediumEvent = createNestedEvent(10, 5, MEDIUM_FILLING_STRING);
        longEvent = createNestedEvent(10, 5, LONG_FILLING_STRING);
        longEvent_1_nestingLevel = createNestedEvent(10, 1, LONG_FILLING_STRING);
    }

    @Benchmark
    public final void deepConvertedMapNavigation(Blackhole blackhole) {
        long size = mediumEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    public final void cborSerializationEstimate(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = mediumEvent.serialize();
        blackhole.consume(cborSerialized);
    }

    @Benchmark
    public final void deepConvertedMapNavigation_longValues_2KB(Blackhole blackhole) {
        long size = longEvent.estimateMemory();
        blackhole.consume(size);
    }

    @Benchmark
    public final void cborSerializationEstimate_longValues_2KB(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = longEvent.serialize();
        blackhole.consume(cborSerialized);
    }

//    @OutputTimeUnit(TimeUnit.MILLISECONDS)
    @Benchmark
    public final void deepConvertedMapNavigation_longValues_2KB_noDeepNesting(Blackhole blackhole) {
        long size = longEvent_1_nestingLevel.estimateMemory();
        blackhole.consume(size);
    }

//    @OutputTimeUnit(TimeUnit.MILLISECONDS)
    @Benchmark
    public final void cborSerializationEstimate_longValues_2KB_noDeepNesting(Blackhole blackhole) throws JsonProcessingException {
        byte[] cborSerialized = longEvent_1_nestingLevel.serialize();
        blackhole.consume(cborSerialized);
    }

    private static Event createNestedEvent(int elementsPerLayer, int layer, String fillingString) {
        double totalElements = Math.pow(elementsPerLayer, layer);
        System.out.println("Total elements: " + totalElements);

        // TODO fill with nested layers
        Event event = new Event();
        event.setField("timestamp", new ConcreteJavaProxy(RubyUtil.RUBY,
                RubyUtil.RUBY_TIMESTAMP_CLASS, new Timestamp()
        ));


        Map<String, Object> map = createSubdocument(elementsPerLayer, layer, fillingString);
        event.setField("custom_data", map);
        return event;
    }

    private static Map<String, Object> createSubdocument(int elementsPerLayer, int layer, String fillingString) {
        Map<String, Object> map = new HashMap<>(elementsPerLayer);
        for (int i = 0; i < elementsPerLayer; i++) {
            if (layer == 0) {
                map.put(String.format("field_%d", i), fillingString);
            } else {
                map.put(String.format("field_%d", i), createSubdocument(elementsPerLayer, layer - 1, fillingString));
            }
        }
        return map;
    }
}
