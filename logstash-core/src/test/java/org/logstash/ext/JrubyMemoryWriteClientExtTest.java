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

package org.logstash.ext;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;
import org.jruby.runtime.ThreadContext;
import org.junit.Test;
import org.logstash.Event;
import org.logstash.RubyTestBase;
import org.logstash.RubyUtil;
import org.logstash.ackedqueue.BatchWriteException;

import static org.hamcrest.CoreMatchers.instanceOf;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.notNullValue;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.Assert.assertThrows;

/**
 * Tests for {@link JrubyMemoryWriteClientExt}.
 */
public final class JrubyMemoryWriteClientExtTest extends RubyTestBase {

    @Test
    public void pushesBatchToQueue() throws Exception {
        final BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue = new ArrayBlockingQueue<>(10);
        final JrubyMemoryWriteClientExt client = JrubyMemoryWriteClientExt.create(queue);
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();

        final List<JrubyEventExtLibrary.RubyEvent> batch = new ArrayList<>();
        for (int i = 0; i < 3; i++) {
            batch.add(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, new Event()));
        }

        client.doPushBatch(context, batch);

        assertThat(queue.size(), is(3));
    }

    @Test(timeout = 30_000)
    public void interruptedBatchPushReportsWrittenCount() throws Exception {
        final BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue = new ArrayBlockingQueue<>(2);
        final JrubyMemoryWriteClientExt client = JrubyMemoryWriteClientExt.create(queue);

        final List<JrubyEventExtLibrary.RubyEvent> batch = new ArrayList<>();
        for (int i = 0; i < 5; i++) {
            batch.add(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, new Event()));
        }

        final AtomicReference<Throwable> thrown = new AtomicReference<>();
        final AtomicBoolean interruptedAfterFailure = new AtomicBoolean();
        final CountDownLatch done = new CountDownLatch(1);

        final Thread writer = new Thread(() -> {
            try {
                client.doPushBatch(RubyUtil.RUBY.getCurrentContext(), batch);
            } catch (Throwable t) {
                thrown.set(t);
                // Thread.interrupted() also clears the flag so the thread can terminate cleanly
                interruptedAfterFailure.set(Thread.interrupted());
            } finally {
                done.countDown();
            }
        });
        writer.start();

        try {
            // wait for the writer to fill the queue and block on the third put
            while (queue.size() < 2 || writer.getState() != Thread.State.WAITING) {
                Thread.sleep(1);
            }
            writer.interrupt();

            assertThat(done.await(10, TimeUnit.SECONDS), is(true));
            assertThat(thrown.get(), notNullValue());
            assertThat(thrown.get(), instanceOf(BatchWriteException.class));
            assertThat(((BatchWriteException) thrown.get()).getWrittenCount(), is(2));
            assertThat(thrown.get().getCause(), instanceOf(InterruptedException.class));
            assertThat("the delivery retry must be able to block again", interruptedAfterFailure.get(), is(false));
            assertThat(new ArrayList<>(queue), is(batch.subList(0, 2)));
        } finally {
            writer.interrupt();
            writer.join(10_000);
        }
    }

    @Test
    public void alreadyInterruptedBatchCanBeRetriedOnSameThread() {
        final BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue = new ArrayBlockingQueue<>(2);
        final JrubyMemoryWriteClientExt client = JrubyMemoryWriteClientExt.create(queue);
        final List<JrubyEventExtLibrary.RubyEvent> batch = List.of(
            JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, new Event()));
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        try {
            Thread.currentThread().interrupt();
            final BatchWriteException failure = assertThrows(BatchWriteException.class,
                () -> client.doPushBatch(context, batch));
            assertThat(failure.getWrittenCount(), is(0));
            assertThat(Thread.currentThread().isInterrupted(), is(false));

            client.doPushBatch(context, batch.subList(failure.getWrittenCount(), batch.size()));
            assertThat(new ArrayList<>(queue), is(batch));
        } finally {
            Thread.interrupted();
        }
    }
}
