/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. See the NOTICE file distributed with
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

import org.logstash.common.BufferedTokenizer;
import org.openjdk.jmh.annotations.Benchmark;
import org.openjdk.jmh.annotations.BenchmarkMode;
import org.openjdk.jmh.annotations.Fork;
import org.openjdk.jmh.annotations.Level;
import org.openjdk.jmh.annotations.Measurement;
import org.openjdk.jmh.annotations.Mode;
import org.openjdk.jmh.annotations.OutputTimeUnit;
import org.openjdk.jmh.annotations.Scope;
import org.openjdk.jmh.annotations.Setup;
import org.openjdk.jmh.annotations.State;
import org.openjdk.jmh.annotations.Warmup;
import org.openjdk.jmh.infra.Blackhole;

import java.util.concurrent.TimeUnit;


@Warmup(iterations = 3, time = 100, timeUnit = TimeUnit.MILLISECONDS)
@Measurement(iterations = 10, time = 3000, timeUnit = TimeUnit.MILLISECONDS)
@Fork(1)
@BenchmarkMode(Mode.Throughput)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Thread)
public class BufferedTokenizerBenchmark {

    private BufferedTokenizer sut;
    private String singleTokenPerFragment;
    private String multipleTokensPerFragment;
    private String multipleTokensSpreadMultipleFragments_1;
    private String multipleTokensSpreadMultipleFragments_2;
    private String multipleTokensSpreadMultipleFragments_3;

    @Setup(Level.Invocation)
    public void setUp() {
        sut = new BufferedTokenizer();
        singleTokenPerFragment = "a".repeat(512) + "\n";

        multipleTokensPerFragment = "a".repeat(512) + "\n" + "b".repeat(512) + "\n" + "c".repeat(512) + "\n";

        multipleTokensSpreadMultipleFragments_1 = "a".repeat(512) + "\n" + "b".repeat(512) + "\n" + "c".repeat(256);
        multipleTokensSpreadMultipleFragments_2 = "c".repeat(256) + "\n" + "d".repeat(512) + "\n" + "e".repeat(256);
        multipleTokensSpreadMultipleFragments_3 = "f".repeat(256) + "\n" + "g".repeat(512) + "\n" + "h".repeat(512) + "\n";
    }

    @Benchmark
    public final void onlyOneTokenPerFragment(Blackhole blackhole) {
        Iterable<String> tokens = sut.extract(singleTokenPerFragment);
        tokens.forEach(blackhole::consume);
        blackhole.consume(tokens);
    }

    @Benchmark
    public final void multipleTokenPerFragment(Blackhole blackhole) {
        Iterable<String> tokens = sut.extract(multipleTokensPerFragment);
        tokens.forEach(blackhole::consume);
        blackhole.consume(tokens);
    }

    @Benchmark
    public final void multipleTokensCrossingMultipleFragments(Blackhole blackhole) {
        Iterable<String> tokens = sut.extract(multipleTokensSpreadMultipleFragments_1);
        tokens.forEach(t -> {});
        blackhole.consume(tokens);

        tokens = sut.extract(multipleTokensSpreadMultipleFragments_2);
        tokens.forEach(t -> {});
        blackhole.consume(tokens);

        tokens = sut.extract(multipleTokensSpreadMultipleFragments_3);
        tokens.forEach(blackhole::consume);
        blackhole.consume(tokens);
    }
}
