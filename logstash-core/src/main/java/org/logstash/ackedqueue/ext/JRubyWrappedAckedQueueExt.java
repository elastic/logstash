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


package org.logstash.ackedqueue.ext;

import java.io.IOException;

import org.jruby.Ruby;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.execution.AbstractWrappedQueueExt;
import org.logstash.execution.QueueReadClientBase;
import org.logstash.ext.JRubyAbstractQueueWriteClientExt;
import org.logstash.ext.JrubyAckedReadClientExt;
import org.logstash.ext.JrubyAckedWriteClientExt;
import org.logstash.ext.JrubyEventExtLibrary;

/**
 * JRuby extension
 */
@JRubyClass(name = "WrappedAckedQueue")
public final class JRubyWrappedAckedQueueExt extends AbstractWrappedQueueExt {

    private static final long serialVersionUID = 1L;

    private JRubyAckedQueueExt queue;

    @JRubyMethod(optional = 8)
    public JRubyWrappedAckedQueueExt initialize(ThreadContext context, IRubyObject[] args) throws IOException {
        args = Arity.scanArgs(context.runtime, args, 8, 0);
        int capacity = RubyFixnum.num2int(args[1]);
        int maxEvents = RubyFixnum.num2int(args[2]);
        int checkpointMaxWrites = RubyFixnum.num2int(args[3]);
        int checkpointMaxAcks = RubyFixnum.num2int(args[4]);
        boolean checkpointRetry = !((RubyBoolean) args[6]).isFalse();
        long queueMaxBytes = RubyFixnum.num2long(args[7]);

        this.queue = JRubyAckedQueueExt.create(args[0].asJavaString(), capacity, maxEvents,
                checkpointMaxWrites, checkpointMaxAcks, checkpointRetry, queueMaxBytes);
        this.queue.open();

        return this;
    }

    public JRubyWrappedAckedQueueExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(name = "queue")
    public JRubyAckedQueueExt rubyGetQueue() {
        return queue;
    }

    public void close() throws IOException {
        queue.close();
    }

    @JRubyMethod(name = {"push", "<<"})
    public void rubyPush(ThreadContext context, IRubyObject event) {
        queue.rubyWrite(context, ((JrubyEventExtLibrary.RubyEvent) event).getEvent());
    }

    @JRubyMethod(name = "read_batch")
    public IRubyObject rubyReadBatch(ThreadContext context, IRubyObject size, IRubyObject wait) {
        return queue.rubyReadBatch(context, size, wait);
    }

    @JRubyMethod(name = "is_empty?")
    public IRubyObject rubyIsEmpty(ThreadContext context) {
        return RubyBoolean.newBoolean(context.runtime, this.queue.isEmpty());
    }

    @Override
    protected JRubyAbstractQueueWriteClientExt getWriteClient(final ThreadContext context) {
        return JrubyAckedWriteClientExt.create(queue);
    }

    @Override
    protected QueueReadClientBase getReadClient() {
        return JrubyAckedReadClientExt.create(queue);
    }

    @Override
    protected IRubyObject doClose(final ThreadContext context) {
        try {
            close();
        } catch (IOException e) {
            throw RubyUtil.newRubyIOError(context.runtime, e);
        }
        return context.nil;
    }
}
