package org.logstash.benchmark;

import org.openjdk.jmh.annotations.*;
import org.openjdk.jmh.infra.Blackhole;

import java.nio.file.Path;
import java.util.concurrent.TimeUnit;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Warmup(iterations = 3, time = 100, timeUnit = TimeUnit.MILLISECONDS)
@Measurement(iterations = 10, time = 3000, timeUnit = TimeUnit.MILLISECONDS)
@Fork(1)
@BenchmarkMode(Mode.Throughput)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Thread)
public class DeadLetterQueueUtilsBenchmark {

    private Path path;
    private static final Pattern precompiledPattern = Pattern.compile("^([0-9]+)\\.log$");

    @Setup(Level.Invocation)
    public void setUp() {
        path = Path.of("1234567890.log");
    }

    @Benchmark
    public final void splitWithPlainRegExp(Blackhole blackhole) {
        int i = extractWithPlainRegExp(path);
        blackhole.consume(i);
    }

    static int extractWithPlainRegExp(Path p) {
        return Integer.parseInt(p.getFileName().toString().split("\\.log")[0]);
    }

    @Benchmark
    public final void splitWithImprovedRegExp(Blackhole blackhole) {
        int i = extractWithImprovedRegExp(path);
        blackhole.consume(i);
    }

    static int extractWithImprovedRegExp(Path p) {
        Pattern pattern = Pattern.compile("^([0-9]+)\\.log$");
        Matcher matcher = pattern.matcher(p.getFileName().toString());
        matcher.find();

        String filename = matcher.group(1);

        return Integer.parseInt(filename);
    }

    @Benchmark
    public final void splitWithImprovedRegExp_precompiledRegExp(Blackhole blackhole) {
        int i = extractWithImprovedRegExp_precompiledRegExp(path);
        blackhole.consume(i);
    }

    static int extractWithImprovedRegExp_precompiledRegExp(Path p) {
        Matcher matcher = precompiledPattern.matcher(p.getFileName().toString());
        matcher.find();

        String filename = matcher.group(1);

        return Integer.parseInt(filename);
    }

    @Benchmark
    public final void splitWithIndexOf(Blackhole blackhole) {
        int i = extractWithIndexOf(path);
        blackhole.consume(i);
    }

    static int extractWithIndexOf(Path p) {
        final String fileName = p.getFileName().toString();
        final int dotIndex = fileName.indexOf(".log");
        return Integer.parseInt(fileName.substring(0, dotIndex));
    }
}
