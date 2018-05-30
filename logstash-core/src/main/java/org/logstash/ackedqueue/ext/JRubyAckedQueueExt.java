package org.logstash.ackedqueue.ext;

import java.io.IOException;
import org.jruby.Ruby;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaObject;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.Event;
import org.logstash.RubyUtil;
import org.logstash.ackedqueue.AckedBatch;
import org.logstash.ackedqueue.Batch;
import org.logstash.ackedqueue.Queue;
import org.logstash.ackedqueue.SettingsImpl;

@JRubyClass(name = "AckedQueue")
public final class JRubyAckedQueueExt extends RubyObject {

    private static final long serialVersionUID = 1L;

    private Queue queue;

    public JRubyAckedQueueExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    public Queue getQueue() {
        return this.queue;
    }

    public static JRubyAckedQueueExt create(String path, int capacity, int maxEvents, int checkpointMaxWrites, int checkpointMaxAcks, long maxBytes) {
        JRubyAckedQueueExt queueExt = new JRubyAckedQueueExt(RubyUtil.RUBY, RubyUtil.ACKED_QUEUE_CLASS);
        queueExt.initializeQueue(path, capacity, maxEvents, checkpointMaxWrites, checkpointMaxAcks, maxBytes);
        return queueExt;
    }

    private void initializeQueue(String path, int capacity, int maxEvents, int checkpointMaxWrites, int checkpointMaxAcks, long maxBytes) {
        this.queue = new Queue(
            SettingsImpl.fileSettingsBuilder(path)
                .capacity(capacity)
                .maxUnread(maxEvents)
                .queueMaxBytes(maxBytes)
                .checkpointMaxAcks(checkpointMaxAcks)
                .checkpointMaxWrites(checkpointMaxWrites)
                .elementClass(Event.class)
                .build()
        );
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

    @JRubyMethod(name = "read_batch", required = 2)
    public IRubyObject ruby_read_batch(ThreadContext context, IRubyObject limit,
        IRubyObject timeout) {
        AckedBatch b;
        try {
            b = readBatch(RubyFixnum.num2int(limit), RubyFixnum.num2int(timeout));
        } catch (IOException e) {
            throw RubyUtil.newRubyIOError(context.runtime, e);
        }
        // TODO: return proper Batch object
        return (b == null) ? context.nil : JavaObject.wrap(context.runtime, b);
    }

    public AckedBatch readBatch(int limit, long timeout) throws IOException {
        Batch b = queue.readBatch(limit, timeout);
        return (b == null) ? null : AckedBatch.create(b);
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
