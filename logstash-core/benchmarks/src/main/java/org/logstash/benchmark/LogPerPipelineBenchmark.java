/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
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

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.ThreadContext;
import org.apache.logging.log4j.core.LoggerContext;
import org.openjdk.jmh.annotations.*;

import java.util.concurrent.TimeUnit;

@Warmup(iterations = 3, time = 100, timeUnit = TimeUnit.MILLISECONDS)
@Measurement(iterations = 10, time = 100, timeUnit = TimeUnit.MILLISECONDS)
@Fork(1)
@BenchmarkMode(Mode.Throughput)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Thread)
public class LogPerPipelineBenchmark {

    private static final int EVENTS_PER_INVOCATION = 10_000_000;

    @Setup
    public void setUp() {
        System.setProperty("ls.log.format", "plain");
    }

    @Benchmark
    @OperationsPerInvocation(EVENTS_PER_INVOCATION)
    public final void logWithScriptingCodeToExecuteAndOneLogPerPipelineEnabled() {
        System.setProperty("log4j.configurationFile", "log4j2-with-script.properties");
        System.setProperty("ls.pipeline.separate_logs", "true");
        logManyLines();
    }

    @Benchmark
    @OperationsPerInvocation(EVENTS_PER_INVOCATION)
    public final void logWithScriptingCodeToExecuteAndOneLogPerPipelineDisabled() {
        System.setProperty("log4j.configurationFile", "log4j2-with-script.properties");
        System.setProperty("ls.pipeline.separate_logs", "false");
        logManyLines();
    }

    @Benchmark
    @OperationsPerInvocation(EVENTS_PER_INVOCATION)
    public final void logWithoutScriptingCodeToExecute() {
        System.setProperty("log4j.configurationFile", "log4j2-without-script.properties");

        logManyLines();
    }

    private void logManyLines() {
        LoggerContext context = LoggerContext.getContext(false);
        context.reconfigure();
        ThreadContext.put("pipeline.id", "pipeline_1");
        Logger logger = LogManager.getLogger(LogPerPipelineBenchmark.class);

        for (int i = 0; i < EVENTS_PER_INVOCATION; ++i) {
            logger.info("log for pipeline 1");
        }
    }
}
