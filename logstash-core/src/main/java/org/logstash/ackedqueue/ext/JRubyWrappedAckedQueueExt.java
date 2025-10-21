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
import java.util.Objects;

import org.jruby.Ruby;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.ackedqueue.Settings;
import org.logstash.ackedqueue.QueueFactoryExt;
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
    private QueueFactoryExt.BatchMetricMode batchMetricMode;

    @JRubyMethod(required=2)
    public JRubyWrappedAckedQueueExt initialize(ThreadContext context, IRubyObject settings, IRubyObject batchMetricMode) throws IOException {
        if (!JavaUtil.isJavaObject(settings)) {
            // We should never get here, but previously had an initialize method
            // that took 7 technically-optional ordered parameters.
            throw new IllegalArgumentException(
                    String.format(
                            "Failed to instantiate JRubyWrappedAckedQueueExt with <%s:%s>",
                            settings.getClass().getName(),
                            settings));
        }

        Objects.requireNonNull(batchMetricMode, "batchMetricMode setting must be non-null");
        if (!JavaUtil.isJavaObject(batchMetricMode)) {
            throw new IllegalArgumentException(
                    String.format(
                            "Failed to instantiate JRubyWrappedAckedQueueExt with <%s:%s>",
                            batchMetricMode.getClass().getName(),
                            batchMetricMode));
        }


        Settings javaSettings = JavaUtil.unwrapJavaObject(settings);
        this.queue = JRubyAckedQueueExt.create(javaSettings);

        this.batchMetricMode = JavaUtil.unwrapJavaObject(batchMetricMode);
        this.queue.open();

        return this;
    }

    public static JRubyWrappedAckedQueueExt create(ThreadContext context, Settings settings, QueueFactoryExt.BatchMetricMode batchMetricMode) throws IOException {
        return new JRubyWrappedAckedQueueExt(context.runtime, RubyUtil.WRAPPED_ACKED_QUEUE_CLASS, settings, batchMetricMode);
    }

    public JRubyWrappedAckedQueueExt(Ruby runtime, RubyClass metaClass, Settings settings, QueueFactoryExt.BatchMetricMode batchMetricMode) throws IOException {
        super(runtime, metaClass);
        this.batchMetricMode = Objects.requireNonNull(batchMetricMode, "batchMetricMode setting must be non-null");
        this.queue = JRubyAckedQueueExt.create(settings);
        this.queue.open();
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
        return JrubyAckedReadClientExt.create(queue, batchMetricMode);
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
