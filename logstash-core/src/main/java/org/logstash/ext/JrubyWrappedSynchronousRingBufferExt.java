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

import java.util.concurrent.LinkedBlockingDeque;
import java.util.concurrent.BlockingDeque;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyNumeric;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.execution.AbstractWrappedQueueExt;
import org.logstash.execution.QueueReadClientBase;

/**
 * JRuby extension to wrap in memory ring buffer queue
 * */
@JRubyClass(name = "WrappedSynchronousRingBuffer")
public final class JrubyWrappedSynchronousRingBufferExt extends AbstractWrappedQueueExt {

    private static final long serialVersionUID = 1L;

    private BlockingDeque<JrubyEventExtLibrary.RubyEvent> queue;

    public JrubyWrappedSynchronousRingBufferExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    @SuppressWarnings("unchecked")
    public JrubyWrappedSynchronousRingBufferExt initialize(final ThreadContext context,
        IRubyObject size) {
        int typedSize = ((RubyNumeric)size).getIntValue();
        this.queue = new LinkedBlockingDeque<>(typedSize);
        return this;
    }

    @Override
    protected JRubyAbstractQueueWriteClientExt getWriteClient(final ThreadContext context) {
        return JrubyRecentMemoryWriteClientExt.create(queue);
    }

    @Override
    protected QueueReadClientBase getReadClient() {
        // batch size and timeout are currently hard-coded to 125 and 50ms as values observed
        // to be reasonable tradeoffs between latency and throughput per PR #8707
        return JrubyRecentMemoryReadClientExt.create(queue, 125, 50);
    }

    @Override
    public IRubyObject doClose(final ThreadContext context) {
        // no op
        return this;
    }

}
