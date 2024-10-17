package org.logstash.benchmark;

import org.jruby.RubyArray;
import org.jruby.RubyString;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.common.BufferedTokenizerExt;
import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.BenchmarkMode;
import org.openjdk.jmh.annotations.Fork;
import org.openjdk.jmh.annotations.Level;
import org.openjdk.jmh.annotations.Measurement;
import org.openjdk.jmh.annotations.Mode;
import org.openjdk.jmh.annotations.OperationsPerInvocation;
import org.openjdk.jmh.annotations.OutputTimeUnit;
import org.openjdk.jmh.annotations.Scope;
import org.openjdk.jmh.annotations.Setup;
import org.openjdk.jmh.annotations.State;
import org.openjdk.jmh.annotations.Warmup;
import org.openjdk.jmh.infra.Blackhole;

import java.util.concurrent.TimeUnit;

import static org.logstash.RubyUtil.RUBY;

@Warmup(iterations = 3, time = 100, timeUnit = TimeUnit.MILLISECONDS)
@Measurement(iterations = 10, time = 100, timeUnit = TimeUnit.MILLISECONDS)
@Fork(1)
@BenchmarkMode(Mode.Throughput)
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@State(Scope.Thread)
public class BufferedTokenizerExtBenchmark {

    private BufferedTokenizerExt sut;
    private ThreadContext context;
    private RubyString singleTokenPerFragment;
    private RubyString multipleTokensPerFragment;
    private RubyString multipleTokensSpreadMultipleFragments_1;
    private RubyString multipleTokensSpreadMultipleFragments_2;
    private RubyString multipleTokensSpreadMultipleFragments_3;

    @Setup(Level.Invocation)
    public void setUp() {
        sut = new BufferedTokenizerExt(RubyUtil.RUBY, RubyUtil.BUFFERED_TOKENIZER);
        context = RUBY.getCurrentContext();
        IRubyObject[] args = {};
        sut.init(context, args);
        singleTokenPerFragment = RubyUtil.RUBY.newString("a".repeat(512) + "\n");

        multipleTokensPerFragment = RubyUtil.RUBY.newString("a".repeat(512) + "\n" + "b".repeat(512) + "\n" + "c".repeat(512) + "\n");

        multipleTokensSpreadMultipleFragments_1 = RubyUtil.RUBY.newString("a".repeat(512) + "\n" + "b".repeat(512) + "\n" + "c".repeat(256));
        multipleTokensSpreadMultipleFragments_2 = RubyUtil.RUBY.newString("c".repeat(256) + "\n" + "d".repeat(512) + "\n" + "e".repeat(256));
        multipleTokensSpreadMultipleFragments_3 = RubyUtil.RUBY.newString("f".repeat(256) + "\n" + "g".repeat(512) + "\n" + "h".repeat(512) + "\n");
    }

    @SuppressWarnings("unchecked")
    @Benchmark
    public final void onlyOneTokenPerFragment(Blackhole blackhole) {
        RubyArray<RubyString> tokens = (RubyArray<RubyString>) sut.extract(context, singleTokenPerFragment);
        blackhole.consume(tokens);
    }

    @SuppressWarnings("unchecked")
    @Benchmark
    public final void multipleTokenPerFragment(Blackhole blackhole) {
        RubyArray<RubyString> tokens = (RubyArray<RubyString>) sut.extract(context, multipleTokensPerFragment);
        blackhole.consume(tokens);
    }

    @SuppressWarnings("unchecked")
    @Benchmark
    public final void multipleTokensCrossingMultipleFragments(Blackhole blackhole) {
        RubyArray<RubyString> tokens = (RubyArray<RubyString>) sut.extract(context, multipleTokensSpreadMultipleFragments_1);
        blackhole.consume(tokens);

        tokens = (RubyArray<RubyString>) sut.extract(context, multipleTokensSpreadMultipleFragments_2);
        blackhole.consume(tokens);

        tokens = (RubyArray<RubyString>) sut.extract(context, multipleTokensSpreadMultipleFragments_3);
        blackhole.consume(tokens);
    }
}
