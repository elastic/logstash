package com.logstash;

import org.openjdk.jmh.annotations.*;
import org.openjdk.jmh.infra.Blackhole;
import org.openjdk.jmh.profile.GCProfiler;
import org.openjdk.jmh.runner.Runner;
import org.openjdk.jmh.runner.RunnerException;
import org.openjdk.jmh.runner.options.Options;
import org.openjdk.jmh.runner.options.OptionsBuilder;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.security.SecureRandom;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.TimeUnit;

@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MICROSECONDS)
@Warmup(iterations = 20, time = 2, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 16, time = 250, timeUnit = TimeUnit.MILLISECONDS)
@Fork(2)
public class EventSerializeBenchmark {
    public static void main(String[] args) throws RunnerException {
        Options opt = new OptionsBuilder()
                .include(EventSerializeBenchmark.class.getSimpleName())
                .threads(4)
                .addProfiler( GCProfiler.class )
                .build();

        new Runner(opt).run();
    }

    @Benchmark
    public void dUniqueByteSerialize(Blackhole bh) {
        bh.consume(UniqueThreadState.event().byteSerialize());
    }

    @Benchmark
    public void dUniqueJSONSerialize(Blackhole bh) {
        try {
            bh.consume(UniqueThreadState.event().toJson());
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Benchmark
    public void cTypicalByteSerialize(Blackhole bh) {
        bh.consume(TypicalThreadState.event().byteSerialize());
    }

    @Benchmark
    public void cTypicalJSONSerialize(Blackhole bh) {
        try {
            bh.consume(TypicalThreadState.event().toJson());
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Benchmark
    public void bMediumByteSerialize(Blackhole bh) {
        bh.consume(MediumThreadState.event().byteSerialize());
    }

    @Benchmark
    public void bMediumJSONSerialize(Blackhole bh) {
        try {
            bh.consume(MediumThreadState.event().toJson());
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Benchmark
    public void aaLargeByteSerialize(Blackhole bh) {
        bh.consume(LargeThreadState.event().byteSerialize());
    }

    @Benchmark
    public void aaLargeJSONSerialize(Blackhole bh) {
        try {
            bh.consume(LargeThreadState.event().toJson());
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Benchmark
    public void aExtraLargeByteSerialize(Blackhole bh) {
        bh.consume(ExtraLargeThreadState.event().byteSerialize());
    }

    @Benchmark
    public void aExtraLargeJSONSerialize(Blackhole bh) {
        try {
            bh.consume(ExtraLargeThreadState.event().toJson());
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Benchmark
    public void eCannedByteSerialize(Blackhole bh) {
        Event e = CannedThreadState.event();
        bh.consume(e.byteSerialize());
    }

    @Benchmark
    public void eCannedJSONSerialize(Blackhole bh) {
        try {
            bh.consume(CannedThreadState.event().toJson());
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public final static class Randomizer {
        private static final SecureRandom random = new SecureRandom();
        private static final Random rng = new Random();

        public static String nextString() {
            return nextBigInteger().toString(32);
        }

        public static String nextBigString() {

            return nextString() +
                    nextString() +
                    nextString() +
                    nextString() +
                    nextString() +
                    nextString();
        }

        public static BigInteger nextBigInteger() {
            return new BigInteger(130, random);
        }

        public static BigDecimal nextBigDecimal() {
            return BigDecimal.valueOf(nextDouble() / 3.0);
        }

        public static double nextDouble() {
            return nextBigInteger().doubleValue();
        }

        public static long nextLong() {
            return nextBigInteger().longValue();
        }

        public static int nextInt() {
            return nextBigInteger().intValue();
        }

        public static long nextEpoch() {
            int ago = rng.nextInt(7 * 24 * 60 * 60 * 1000);
            return System.currentTimeMillis() - ago;
        }
    }

    @State(Scope.Thread)
    public static class CannedThreadState extends ThreadStateBase {
        public static Event cached_event;

        public static Event event() {
            if (cached_event == null) {
                Map meta = new HashMap<String, Object>();
                meta.put(EventSerializeBenchmark.Randomizer.nextString(), EventSerializeBenchmark.Randomizer.nextString());
                cached_event = new Event(buildRandomMap(meta));
                decorateEventRandomly(cached_event);
            }
            return cached_event;
        }
    }

    @State(Scope.Thread)
    public static class TypicalThreadState extends ThreadStateBase {
        public static Event event() {
            Event event = new Event(buildTypicalMap(new HashMap<>()));
            decorateEventTypically(event);
            return event;
        }
    }

    @State(Scope.Thread)
    public static class MediumThreadState extends ThreadStateBase {
        public static Event event() {
            Event event = new Event(buildMediumMap(null));
            decorateEventTypically(event);
            return event;
        }
    }

    @State(Scope.Thread)
    public static class LargeThreadState extends ThreadStateBase {
        public static Event event() {
            Event event = new Event(buildLargeMap(null));
            decorateEventTypically(event);
            return event;
        }
    }

    @State(Scope.Thread)
    public static class ExtraLargeThreadState extends ThreadStateBase {
        public static Event event() {
            Event event = new Event(buildExtraLargeMap(null));
            decorateEventTypically(event);
            return event;
        }
    }

    @State(Scope.Thread)
    public static class UniqueThreadState extends ThreadStateBase {
        public static Event event() {
            Map meta = new HashMap<String, Object>();
            meta.put(EventSerializeBenchmark.Randomizer.nextString(), EventSerializeBenchmark.Randomizer.nextString());
            Event event = new Event(buildRandomMap(meta));
            decorateEventRandomly(event);
            return event;
        }
    }
}
