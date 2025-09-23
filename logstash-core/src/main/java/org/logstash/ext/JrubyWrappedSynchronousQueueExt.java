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

import java.util.Objects;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyNumeric;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.ackedqueue.QueueFactoryExt;
import org.logstash.execution.AbstractWrappedQueueExt;
import org.logstash.execution.QueueReadClientBase;

/**
 * JRuby extension to wrap in memory queue
 * */
@JRubyClass(name = "WrappedSynchronousQueue")
public final class JrubyWrappedSynchronousQueueExt extends AbstractWrappedQueueExt {

    private static final long serialVersionUID = 1L;

    private transient BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue;
    private QueueFactoryExt.BatchMetricMode batchMetricMode;

    public JrubyWrappedSynchronousQueueExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    private JrubyWrappedSynchronousQueueExt(final Ruby runtime, final RubyClass metaClass,
                                           int size, QueueFactoryExt.BatchMetricMode batchMetricMode) {
        super(runtime, metaClass);
        this.queue = new ArrayBlockingQueue<>(size);
        this.batchMetricMode = Objects.requireNonNull(batchMetricMode, "batchMetricMode setting must be non-null");
    }

    @JRubyMethod
    @SuppressWarnings("unchecked")
    public JrubyWrappedSynchronousQueueExt initialize(final ThreadContext context,
                                                      IRubyObject size,
                                                      IRubyObject batchMetricMode) {
        if (!JavaUtil.isJavaObject(batchMetricMode)) {
            throw new IllegalArgumentException(
                    String.format(
                            "Failed to instantiate JrubyWrappedSynchronousQueueExt with <%s:%s>",
                            batchMetricMode.getClass().getName(),
                            batchMetricMode));
        }

        int typedSize = ((RubyNumeric)size).getIntValue();
        this.queue = new ArrayBlockingQueue<>(typedSize);
        Objects.requireNonNull(batchMetricMode, "batchMetricMode setting must be non-null");
        this.batchMetricMode = JavaUtil.unwrapJavaObject(batchMetricMode);
        return this;
    }

    public static JrubyWrappedSynchronousQueueExt create(final ThreadContext context, int size,
                                                        QueueFactoryExt.BatchMetricMode batchMetricMode) {
        return new JrubyWrappedSynchronousQueueExt(context.runtime, RubyUtil.WRAPPED_SYNCHRONOUS_QUEUE_CLASS, size, batchMetricMode);
    }

    @Override
    protected JRubyAbstractQueueWriteClientExt getWriteClient(final ThreadContext context) {
        return JrubyMemoryWriteClientExt.create(queue);
    }

    @Override
    protected QueueReadClientBase getReadClient() {
        // batch size and timeout are currently hard-coded to 125 and 50ms as values observed
        // to be reasonable tradeoffs between latency and throughput per PR #8707
        return JrubyMemoryReadClientExt.create(queue, 125, 50, batchMetricMode);
    }

    @Override
    public IRubyObject doClose(final ThreadContext context) {
        // no op
        return this;
    }

}
