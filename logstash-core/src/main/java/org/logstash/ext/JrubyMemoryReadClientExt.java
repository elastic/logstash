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

import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.logstash.RubyUtil;
import org.logstash.common.LsQueueUtils;
import org.logstash.execution.MemoryReadBatch;
import org.logstash.execution.QueueBatch;
import org.logstash.execution.QueueReadClientBase;

/**
 * JRuby extension to provide an implementation of queue client for InMemory queue
 * */
@JRubyClass(name = "MemoryReadClient", parent = "QueueReadClientBase")
public final class JrubyMemoryReadClientExt extends QueueReadClientBase {

    private static final long serialVersionUID = 1L;

    @SuppressWarnings({"rawtypes", "serial"}) private BlockingQueue queue;

    public JrubyMemoryReadClientExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @SuppressWarnings("rawtypes")
    private JrubyMemoryReadClientExt(final Ruby runtime, final RubyClass metaClass,
                                     BlockingQueue queue, int batchSize, int waitForMillis) {
        super(runtime, metaClass);
        this.queue = queue;
        this.batchSize = batchSize;
        this.waitForNanos = TimeUnit.NANOSECONDS.convert(waitForMillis, TimeUnit.MILLISECONDS);
        this.waitForMillis = waitForMillis;
    }

    @SuppressWarnings("rawtypes")
    public static JrubyMemoryReadClientExt create(BlockingQueue queue, int batchSize,
                                                  int waitForMillis) {
        return new JrubyMemoryReadClientExt(RubyUtil.RUBY,
                RubyUtil.MEMORY_READ_CLIENT_CLASS, queue, batchSize, waitForMillis);
    }

    @Override
    public void close() {
        // no-op
    }

    @Override
    public boolean isEmpty() {
        return queue.isEmpty();
    }

    @Override
    public QueueBatch newBatch() {
        return MemoryReadBatch.create();
    }

    @Override
    @SuppressWarnings("unchecked")
    public QueueBatch readBatch() throws InterruptedException {
        final MemoryReadBatch batch = MemoryReadBatch.create(LsQueueUtils.drain(queue, batchSize, waitForNanos));
        startMetrics(batch);
        return batch;
    }
}
