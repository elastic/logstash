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

import java.util.Iterator;
import java.util.concurrent.TimeUnit;


@Warmup(iterations = 3, time = 100, timeUnit = TimeUnit.MILLISECONDS)
@Fork(value = 1, jvmArgsAppend = {"-Xmx8g", "-Xms8g"})
@BenchmarkMode(Mode.SingleShotTime)
@OutputTimeUnit(TimeUnit.MICROSECONDS)
@State(Scope.Thread)
public class BufferedTokenizerConsumptionBenchmark {

    private BufferedTokenizer sut;
    private Iterator<String> iterator;
    private String singleTokenPerFragment;

    @Setup(Level.Iteration)
    public void setUp() {
        sut = new BufferedTokenizer();
        singleTokenPerFragment = "a".repeat(20) + "\n";
        iterator = sut.extract(singleTokenPerFragment).iterator();
        for (int i = 0; i < 10_000_000; i++) {
            sut.extract(singleTokenPerFragment);
        }
    }

    @Measurement(iterations = 120, batchSize = 10_000_000)
    @Benchmark
    @GroupThreads(1)
    public final void repeatedExtractInvocations(Blackhole blackhole) {
        blackhole.consume(iterator.next());
    }
}
