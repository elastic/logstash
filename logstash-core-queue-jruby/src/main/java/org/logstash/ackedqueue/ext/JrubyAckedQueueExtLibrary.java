package org.logstash.ackedqueue.ext;

import com.logstash.Event;
import com.logstash.ext.JrubyEventExtLibrary;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.Library;
import org.logstash.ackedqueue.Batch;
import org.logstash.ackedqueue.ElementDeserialiser;
import org.logstash.ackedqueue.MemorySettings;
import org.logstash.ackedqueue.Queue;
import org.logstash.ackedqueue.Settings;
import org.logstash.common.io.CheckpointIOFactory;
import org.logstash.common.io.FileCheckpointIO;
import org.logstash.common.io.MmapPageIO;
import org.logstash.common.io.PageIOFactory;

import java.io.IOException;

public class JrubyAckedQueueExtLibrary implements Library {

    public void load(Ruby runtime, boolean wrap) throws IOException {
        RubyModule module = runtime.defineModule("LogStash");

        RubyClass clazz = runtime.defineClassUnder("AckedQueue", runtime.getObject(), new ObjectAllocator() {
            public IRubyObject allocate(Ruby runtime, RubyClass rubyClass) {
                return new RubyAckedQueue(runtime, rubyClass);
            }
        }, module);

        clazz.defineAnnotatedMethods(RubyAckedQueue.class);
    }

    // TODO:
    // as a simplified first prototyping implementation, the Settings class is not exposed and the queue elements
    // are assumed to be logstash Event.


    @JRubyClass(name = "AckedQueue", parent = "Object")
    public static class RubyAckedQueue extends RubyObject {
        private Queue queue;

        public RubyAckedQueue(Ruby runtime, RubyClass klass) {
            super(runtime, klass);
        }

        public Queue getQueue() {
            return this.queue;
        }

        // def initialize
        @JRubyMethod(name = "initialize", optional = 2)
        public IRubyObject ruby_initialize(ThreadContext context, IRubyObject[] args)
        {
            args = Arity.scanArgs(context.runtime, args, 2, 0);

            int capacity = RubyFixnum.num2int(args[1]);

            Settings s = new MemorySettings(args[0].asJavaString());
            PageIOFactory pageIOFactory = (pageNum, size, path) -> new MmapPageIO(pageNum, size, path);
            CheckpointIOFactory checkpointIOFactory = (source) -> new FileCheckpointIO(source);
            s.setCapacity(capacity);
            s.setElementIOFactory(pageIOFactory);
            s.setCheckpointIOFactory(checkpointIOFactory);
            s.setElementDeserialiser(new ElementDeserialiser(Event.class));

            this.queue = new Queue(s);

            return context.nil;
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
