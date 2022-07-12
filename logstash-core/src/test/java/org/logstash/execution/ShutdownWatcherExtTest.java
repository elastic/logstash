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


package org.logstash.execution;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.stream.IntStream;
import javax.annotation.concurrent.NotThreadSafe;

import org.apache.logging.log4j.junit.LoggerContextRule;
import org.apache.logging.log4j.test.appender.ListAppender;
import org.assertj.core.api.Assertions;
import org.jruby.RubySystemExit;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Before;
import org.junit.ClassRule;
import org.junit.Test;
import org.logstash.RubyTestBase;
import org.logstash.RubyUtil;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

/**
 * Tests for {@link ShutdownWatcherExt}.
 */
@NotThreadSafe
public final class ShutdownWatcherExtTest extends RubyTestBase {

    private static final String CONFIG = "log4j2-test1.xml";
    private static final Path PIPELINE_TEMPLATE = Paths.get("./src/test/resources/shutdown_watcher_ext_pipeline_template.rb").toAbsolutePath();
    private ListAppender appender;

    @ClassRule
    public static LoggerContextRule CTX = new LoggerContextRule(CONFIG);

    @Before
    public void setup() {
        appender = CTX.getListAppender("EventLogger").clear();
    }

    @Test
    public void pipelineWithUnsafeShutdownShouldForceShutdown() throws InterruptedException, IOException {
        String pipeline = resolvedPipeline(false);
        watcherShutdownStallingPipeline(pipeline);

        // non drain pipeline should print stall msg
        boolean printStalling = appender.getMessages().stream().anyMatch((msg) -> msg.contains("stalling"));
        assertTrue(printStalling);
    }


    @Test
    public void pipelineWithDrainShouldNotPrintStallMsg() throws InterruptedException, IOException {
        String pipeline = resolvedPipeline(true);
        watcherShutdownStallingPipeline(pipeline);

        boolean printStalling = appender.getMessages().stream().anyMatch((msg) -> msg.contains("stalling"));
        assertFalse(printStalling);
    }

    private void watcherShutdownStallingPipeline(String rubyScript) throws InterruptedException {
        final ExecutorService exec = Executors.newSingleThreadExecutor();
        try {
            final Future<IRubyObject> res = exec.submit(() -> {
                final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
                ShutdownWatcherExt.setUnsafeShutdown(context, null, context.tru);
                return new ShutdownWatcherExt(context.runtime, RubyUtil.SHUTDOWN_WATCHER_CLASS)
                        .initialize(
                                context, new IRubyObject[]{
                                        RubyUtil.RUBY.evalScriptlet(rubyScript),
                                        context.runtime.newFloat(0.01)
                                }
                        ).start(context);
            });
            res.get();
            Assertions.fail("Shutdown watcher did not invoke system exit(-1)");
        } catch (final ExecutionException ex) {
            final RaiseException cause = (RaiseException) ex.getCause();
            Assertions.assertThat(cause.getException()).isInstanceOf(RubySystemExit.class);
        } finally {
            exec.shutdownNow();
            final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
            ShutdownWatcherExt.setUnsafeShutdown(context, null, context.fals);
            if (!exec.awaitTermination(30L, TimeUnit.SECONDS)) {
                Assertions.fail("Failed to shut down shutdown watcher thread");
            }
        }
    }

    private static String getPipelineTemplate() throws IOException {
        return new String(Files.readAllBytes(PIPELINE_TEMPLATE));
    }

    private static String resolvedPipeline(Boolean isDraining) throws IOException {
        return getPipelineTemplate().replace("%{value_placeholder}", isDraining.toString());
    }
}
