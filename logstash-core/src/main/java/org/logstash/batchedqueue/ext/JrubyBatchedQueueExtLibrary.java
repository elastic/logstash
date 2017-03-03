package org.logstash.batchedqueue.ext;

import org.logstash.Event;
import org.logstash.ext.JrubyEventExtLibrary;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyBoolean;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.Library;
import org.logstash.batchedqueue.Queue;

import java.io.IOException;
import java.util.List;


public class JrubyBatchedQueueExtLibrary implements Library {

    public void load(Ruby runtime, boolean wrap) throws IOException {
        RubyModule module = runtime.defineModule("LogStash");

        RubyClass clazz = runtime.defineClassUnder("BatchedQueue", runtime.getObject(), new ObjectAllocator() {
            public IRubyObject allocate(Ruby runtime, RubyClass rubyClass) {
                return new RubyBatchedQueue(runtime, rubyClass);
            }
        }, module);

        clazz.defineAnnotatedMethods(RubyBatchedQueue.class);
    }

    @JRubyClass(name = "BatchedQueue", parent = "Object")
    public static class RubyBatchedQueue extends RubyObject {
        private Queue queue;

        public RubyBatchedQueue(Ruby runtime, RubyClass klass) {
            super(runtime, klass);
        }

        public Queue getQueue() {
            return this.queue;
        }

        // def initialize
        @JRubyMethod(name = "initialize", required = 1)
        public IRubyObject ruby_initialize(ThreadContext context, IRubyObject limit)
        {

            int _limit = RubyFixnum.num2int(limit);

            this.queue = new Queue(_limit);

            return context.nil;
        }

        @JRubyMethod(name = {"write", "<<"}, required = 1)
        public IRubyObject ruby_write(ThreadContext context, IRubyObject event)
        {
            if (!(event instanceof JrubyEventExtLibrary.RubyEvent)) {
                throw context.runtime.newTypeError("wrong argument type " + event.getMetaClass() + " (expected LogStash::Event)");
            }

            this.queue.write(event);

            return context.nil;
        }

        @JRubyMethod(name = "read_batch", required = 1)
        public IRubyObject ruby_read_batch(ThreadContext context, IRubyObject timeout)
        {
            List result = this.queue.readBatch(RubyFixnum.num2int(timeout));
            return result == null ? context.nil : context.runtime.newArray(result);
        }

        @JRubyMethod(name = "empty?")
        public IRubyObject ruby_empty(ThreadContext context)
        {

            return RubyBoolean.newBoolean(context.runtime, this.queue.isEmpty());
        }

        @JRubyMethod(name = "close")
        public IRubyObject ruby_close(ThreadContext context)
        {

            this.queue.close();
            return context.nil;
        }

    }
}
