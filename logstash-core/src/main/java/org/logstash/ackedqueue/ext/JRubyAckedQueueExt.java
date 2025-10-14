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

import co.elastic.logstash.api.Metric;
import org.jruby.Ruby;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.Event;
import org.logstash.RubyUtil;
import org.logstash.ackedqueue.AckedBatch;
import org.logstash.ackedqueue.Batch;
import org.logstash.ackedqueue.Queue;
import org.logstash.ackedqueue.QueueExceptionMessages;
import org.logstash.ackedqueue.Settings;
import org.logstash.ackedqueue.SettingsImpl;
import org.logstash.plugins.NamespacedMetricImpl;


/**
 * JRuby extension to wrap a persistent queue instance.
 */
@JRubyClass(name = "AckedQueue")
public final class JRubyAckedQueueExt extends RubyObject {

    private static final long serialVersionUID = 1L;

    @SuppressWarnings("serial")
    private Queue queue;

    public JRubyAckedQueueExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    public Queue getQueue() {
        return this.queue;
    }

    @Deprecated
    public static JRubyAckedQueueExt create(final Settings settings) {
        return create(settings, NamespacedMetricImpl.getNullMetric());
    }

    public static JRubyAckedQueueExt create(final Settings settings, final Metric metric) {
        JRubyAckedQueueExt queueExt = new JRubyAckedQueueExt(RubyUtil.RUBY, RubyUtil.ACKED_QUEUE_CLASS);
        queueExt.queue = new Queue(settings, metric);
        return queueExt;
    }

    /**
     * Helper method for retrieving a ruby-usable {@link Settings.Builder} with the provided path as its directory,
     * using {@link Event} as its element-type.
     *
     * @param context the ruby thread context
     * @param recv noop receiver (will be rubified LogStash::AckedQueue class)
     * @param path the path to the queue
     * @return a ruby-usable proxy for {@link Settings.Builder}
     */
    @JRubyMethod(meta = true, name = "file_settings_builder")
    public static IRubyObject fileSettingsBuilder(final ThreadContext context, IRubyObject recv, final RubyString path) {
        final Settings.Builder settingsBuilder = SettingsImpl
                .fileSettingsBuilder(path.asJavaString())
                .elementClass(Event.class);
        return JavaUtil.convertJavaToRuby(context.runtime, settingsBuilder);
    }

    @JRubyMethod(name = "max_unread_events")
    public IRubyObject ruby_max_unread_events(ThreadContext context) {
        return context.runtime.newFixnum(queue.getMaxUnread());
    }

    @JRubyMethod(name = "max_size_in_bytes")
    public IRubyObject ruby_max_size_in_bytes(ThreadContext context) {
        return context.runtime.newFixnum(queue.getMaxBytes());
    }

    @JRubyMethod(name = "page_capacity")
    public IRubyObject ruby_page_capacity(ThreadContext context) {
        return context.runtime.newFixnum(queue.getPageCapacity());
    }

    @JRubyMethod(name = "dir_path")
    public RubyString ruby_dir_path(ThreadContext context) {
        return context.runtime.newString(queue.getDirPath());
    }

    @JRubyMethod(name = "persisted_size_in_bytes")
    public IRubyObject ruby_persisted_size_in_bytes(ThreadContext context) {
        return context.runtime.newFixnum(queue.getPersistedByteSize());
    }

    @JRubyMethod(name = "acked_count")
    public IRubyObject ruby_acked_count(ThreadContext context) {
        return context.runtime.newFixnum(queue.getAckedCount());
    }

    @JRubyMethod(name = "unacked_count")
    public IRubyObject ruby_unacked_count(ThreadContext context) {
        return context.runtime.newFixnum(queue.getUnackedCount());
    }

    @JRubyMethod(name = "unread_count")
    public IRubyObject ruby_unread_count(ThreadContext context) {
        return context.runtime.newFixnum(queue.getUnreadCount());
    }

    public void open() throws IOException {
        queue.open();
    }

    public void rubyWrite(ThreadContext context, Event event) {
        try {
            this.queue.write(event);
        } catch (IOException e) {
            throw RubyUtil.newRubyIOError(context.runtime, e);
        }
    }

    public void write(Event event) {
        try {
            this.queue.write(event);
        } catch (IOException e) {
            throw new IllegalStateException(QueueExceptionMessages.UNHANDLED_ERROR_WRITING_TO_QUEUE, e);
        }
    }

    @JRubyMethod(name = "read_batch", required = 2)
    public IRubyObject rubyReadBatch(ThreadContext context, IRubyObject limit, IRubyObject timeout) {
        AckedBatch batch;
        try {
            batch = readBatch(RubyFixnum.num2int(limit), RubyFixnum.num2int(timeout));
        } catch (IOException e) {
            throw RubyUtil.newRubyIOError(context.runtime, e);
        }
        return RubyUtil.toRubyObject(batch);
    }

    public AckedBatch readBatch(int limit, long timeout) throws IOException {
        final Batch batch = queue.readBatch(limit, timeout);
        return Objects.isNull(batch) ? null : AckedBatch.create(batch);
    }

    @JRubyMethod(name = "is_fully_acked?")
    public IRubyObject ruby_is_fully_acked(ThreadContext context) {
        return RubyBoolean.newBoolean(context.runtime, this.queue.isFullyAcked());
    }

    public boolean isEmpty() {
        return queue.isEmpty();
    }

    public void close() throws IOException {
        queue.close();
    }
}
