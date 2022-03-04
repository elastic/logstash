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

import java.io.IOException;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import org.jruby.RubyHash;
import org.jruby.runtime.ThreadContext;
import org.junit.Test;
import org.logstash.RubyTestBase;
import org.logstash.execution.QueueBatch;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

/**
 * Tests for {@link JrubyMemoryReadClientExt}.
 */
public final class JrubyMemoryReadClientExtTest extends RubyTestBase {

    @Test
    public void testInflightBatchesTracking() throws InterruptedException, IOException {
        final BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue =
            new ArrayBlockingQueue<>(10);
        final JrubyMemoryReadClientExt client =
            JrubyMemoryReadClientExt.create(queue, 5, 50);
        final ThreadContext context = client.getRuntime().getCurrentContext();
        final QueueBatch batch = client.readBatch();
        final RubyHash inflight = client.rubyGetInflightBatches(context);
        assertThat(inflight.size(), is(1));
        assertThat(inflight.get(Thread.currentThread().getId()), is(batch));
        client.closeBatch(batch);
        assertThat(client.rubyGetInflightBatches(context).size(), is(0));
    }
}
