package org.logstash.ackedqueue.ext;

import java.io.IOException;
import org.jruby.Ruby;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.Library;
import org.logstash.Event;
import org.logstash.RubyUtil;
import org.logstash.ackedqueue.Batch;
import org.logstash.ackedqueue.Queue;
import org.logstash.ackedqueue.SettingsImpl;
import org.logstash.ackedqueue.io.FileCheckpointIO;
import org.logstash.ackedqueue.io.MmapPageIO;
import org.logstash.ext.JrubyEventExtLibrary;

public final class JrubyAckedQueueExtLibrary implements Library {

    @Override
    public void load(Ruby runtime, boolean wrap) {
        runtime.defineClassUnder(
            "AckedQueue", runtime.getObject(), JrubyAckedQueueExtLibrary.RubyAckedQueue::new,
            runtime.defineModule(RubyUtil.LS_MODULE_NAME)
        ).defineAnnotatedMethods(JrubyAckedQueueExtLibrary.RubyAckedQueue.class);
    }

    // TODO:
    // as a simplified first prototyping implementation, the Settings class is not exposed and the queue elements
    // are assumed to be logstash Event.

    @JRubyClass(name = "AckedQueue")
    public static final class RubyAckedQueue extends RubyObject {

        private static final long serialVersionUID = 1L;

        private Queue queue;

        public RubyAckedQueue(Ruby runtime, RubyClass klass) {
            super(runtime, klass);
        }

        public Queue getQueue() {
            return this.queue;
        }

        // def initialize
        @JRubyMethod(name = "initialize", optional = 7)
        public IRubyObject ruby_initialize(ThreadContext context, IRubyObject[] args)
        {
            args = Arity.scanArgs(context.runtime, args, 7, 0);

            int capacity = RubyFixnum.num2int(args[1]);
            int maxUnread = RubyFixnum.num2int(args[2]);
            int checkpointMaxAcks = RubyFixnum.num2int(args[3]);
            int checkpointMaxWrites = RubyFixnum.num2int(args[4]);
            long queueMaxBytes = RubyFixnum.num2long(args[6]);

            this.queue = new Queue(
                SettingsImpl.fileSettingsBuilder(args[0].asJavaString())
                    .capacity(capacity)
                    .maxUnread(maxUnread)
                    .queueMaxBytes(queueMaxBytes)
                    .checkpointMaxAcks(checkpointMaxAcks)
                    .checkpointMaxWrites(checkpointMaxWrites)
                    .elementIOFactory(MmapPageIO::new)
                    .checkpointIOFactory(FileCheckpointIO::new)
                    .elementClass(Event.class)
                    .build()
            );
            return context.nil;
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
        public IRubyObject ruby_dir_path(ThreadContext context) {
            return context.runtime.newString(queue.getDirPath());
        }

        @JRubyMethod(name = "current_byte_size")
        public IRubyObject ruby_current_byte_size(ThreadContext context) {
            return context.runtime.newFixnum(queue.getCurrentByteSize());
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

        @JRubyMethod(name = "open")
        public IRubyObject ruby_open(ThreadContext context)
        {
            try {
                this.queue.open();
            } catch (IOException e) {
                throw context.runtime.newIOErrorFromException(e);
            }

            return context.nil;
        }

        @JRubyMethod(name = {"write", "<<"}, required = 1)
        public IRubyObject ruby_write(ThreadContext context, IRubyObject event)
        {
            if (!(event instanceof JrubyEventExtLibrary.RubyEvent)) {
                throw context.runtime.newTypeError("wrong argument type " + event.getMetaClass() + " (expected LogStash::Event)");
            }

            long seqNum;
            try {
                seqNum = this.queue.write(((JrubyEventExtLibrary.RubyEvent) event).getEvent());
            } catch (IOException e) {
                throw context.runtime.newIOErrorFromException(e);
            }

            return context.runtime.newFixnum(seqNum);
        }

        @JRubyMethod(name = "read_batch", required = 2)
        public IRubyObject ruby_read_batch(ThreadContext context, IRubyObject limit, IRubyObject timeout)
        {
            Batch b;

            try {
                b = this.queue.readBatch(RubyFixnum.num2int(limit), RubyFixnum.num2int(timeout));
            } catch (IOException e) {
                throw context.runtime.newIOErrorFromException(e);
            }

            // TODO: return proper Batch object
            return (b == null) ? context.nil : new JrubyAckedBatchExtLibrary.RubyAckedBatch(context.runtime, b);
        }

        @JRubyMethod(name = "is_fully_acked?")
        public IRubyObject ruby_is_fully_acked(ThreadContext context)
        {
            return RubyBoolean.newBoolean(context.runtime, this.queue.isFullyAcked());
        }

        @JRubyMethod(name = "is_empty?")
        public IRubyObject ruby_is_empty(ThreadContext context)
        {
            return RubyBoolean.newBoolean(context.runtime, this.queue.isEmpty());
        }

        @JRubyMethod(name = "close")
        public IRubyObject ruby_close(ThreadContext context)
        {
            try {
                this.queue.close();
            } catch (IOException e) {
                throw context.runtime.newIOErrorFromException(e);
            }

            return context.nil;
        }
    }
}
