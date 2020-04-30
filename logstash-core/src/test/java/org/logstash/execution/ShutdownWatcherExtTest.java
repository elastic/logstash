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

import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import javax.annotation.concurrent.NotThreadSafe;
import org.assertj.core.api.Assertions;
import org.jruby.RubySystemExit;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Test;
import org.logstash.RubyUtil;

/**
 * Tests for {@link ShutdownWatcherExt}.
 */
@NotThreadSafe
public final class ShutdownWatcherExtTest {

    @Test
    public void testShouldForceShutdown() throws InterruptedException {
        final ExecutorService exec = Executors.newSingleThreadExecutor();
        try {
            final Future<IRubyObject> res = exec.submit(() -> {
                final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
                ShutdownWatcherExt.setUnsafeShutdown(context, null, context.tru);
                return new ShutdownWatcherExt(context.runtime, RubyUtil.SHUTDOWN_WATCHER_CLASS)
                    .initialize(
                        context, new IRubyObject[]{
                            RubyUtil.RUBY.evalScriptlet(
                                String.join(
                                    "\n",
                                    "pipeline = Object.new",
                                    "reporter = Object.new",
                                    "snapshot = Object.new",
                                    "inflight_count = java.util.concurrent.atomic.AtomicInteger.new",
                                    "snapshot.define_singleton_method(:inflight_count) do",
                                    "inflight_count.increment_and_get + 1",
                                    "end",
                                    "threads = {}",
                                    "snapshot.define_singleton_method(:stalling_threads) do",
                                    "threads",
                                    "end",
                                    "reporter.define_singleton_method(:snapshot) do",
                                    "snapshot",
                                    "end",
                                    "pipeline.define_singleton_method(:thread) do",
                                    "Thread.current",
                                    "end",
                                    "pipeline.define_singleton_method(:reporter) do",
                                    "reporter",
                                    "end",
                                    "pipeline"
                                )
                            ),
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
}
