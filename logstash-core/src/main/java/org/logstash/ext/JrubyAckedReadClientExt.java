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

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.ackedqueue.AckedReadBatch;
import org.logstash.ackedqueue.ext.JRubyAckedQueueExt;
import org.logstash.execution.QueueBatch;
import org.logstash.execution.QueueReadClient;
import org.logstash.execution.QueueReadClientBase;

import java.io.IOException;

/**
 * JRuby extension to provide an implementation of queue client for Persistent queue
 * */
@JRubyClass(name = "AckedReadClient", parent = "QueueReadClientBase")
public final class JrubyAckedReadClientExt extends QueueReadClientBase implements QueueReadClient {

    private static final long serialVersionUID = 1L;

    private JRubyAckedQueueExt queue;

    @JRubyMethod(meta = true, required = 1)
    public static JrubyAckedReadClientExt create(final ThreadContext context,
        final IRubyObject recv, final IRubyObject queue) {
        return new JrubyAckedReadClientExt(
            context.runtime, RubyUtil.ACKED_READ_CLIENT_CLASS, queue
        );
    }

    public static JrubyAckedReadClientExt create(IRubyObject queue) {
        return new JrubyAckedReadClientExt(RubyUtil.RUBY, RubyUtil.ACKED_READ_CLIENT_CLASS, queue);
    }

    public JrubyAckedReadClientExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    private JrubyAckedReadClientExt(final Ruby runtime, final RubyClass metaClass,
        final IRubyObject queue) {
        super(runtime, metaClass);
        this.queue = (JRubyAckedQueueExt)queue;
    }

    @Override
    public void close() throws IOException {
        queue.close();
    }

    @Override
    public boolean isEmpty() {
        return queue.isEmpty();
    }

    @Override
    public QueueBatch newBatch() {
        return AckedReadBatch.create();
    }

    @Override
    public QueueBatch readBatch() {
        final AckedReadBatch batch = AckedReadBatch.create(queue, batchSize, waitForMillis);
        startMetrics(batch);
        return batch;
    }

}
