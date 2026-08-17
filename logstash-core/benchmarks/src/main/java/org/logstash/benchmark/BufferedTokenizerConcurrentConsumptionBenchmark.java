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
import org.openjdk.jmh.annotations.Group;
import org.openjdk.jmh.annotations.GroupThreads;
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
@Measurement(iterations = 60, time = 3000, timeUnit = TimeUnit.MILLISECONDS)
@Fork(value = 1, jvmArgsAppend = {"-Xmx4g", "-Xms4g"})
@BenchmarkMode(Mode.Throughput)
@OutputTimeUnit(TimeUnit.MICROSECONDS)
@State(Scope.Group)
public class BufferedTokenizerConcurrentConsumptionBenchmark {

    public static final String SOME_NEW_TOKEN = "Some new token\n";
    private BufferedTokenizer sut;

    @Setup(Level.Iteration)
    public void prepare() {
        sut = new BufferedTokenizer("\n", 50);
    }
    
    // ---- multiple writers - single reader
    
    @Benchmark
    @Group("multi_writers_single_reader")
    @GroupThreads(8)
    public void mwsr_multipleWriters() {
        sut.extract("Some new token\n");
    }

    @Benchmark
    @Group("multi_writers_single_reader")
    @GroupThreads(1)
    public void mwsr_singleReader(Blackhole blackhole) {
        String token = sut.extract("\n").iterator().next();
        blackhole.consume(token);
    }

    // ---- single writer - single reader

    @Benchmark
    @Group("single_writer_single_reader")
    @GroupThreads(1)
    public void swsr_singleWriter() {
        sut.extract(SOME_NEW_TOKEN);
    }

    @Benchmark
    @Group("single_writer_single_reader")
    @GroupThreads(1)
    public void swsr_singleReader(Blackhole blackhole) {
        String token = sut.extract("\n").iterator().next();
        blackhole.consume(token);
    }

    // ---- single writer - multiple reader

    @Benchmark
    @Group("single_writer_multi_reader")
    @GroupThreads(1)
    public void swmr_singleWriter() {
        sut.extract(SOME_NEW_TOKEN);
    }

    @Benchmark
    @Group("single_writer_multi_reader")
    @GroupThreads(8)
    public void swmr_multiReader(Blackhole blackhole) {
        String token = sut.extract("\n").iterator().next();
        blackhole.consume(token);
    }
}
