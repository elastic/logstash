package org.logstash.ackedqueue.ext;

import com.logstash.Event;
import com.logstash.ext.JrubyEventExtLibrary;
import org.jruby.*;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.Library;
import org.logstash.ackedqueue.*;
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

    }

    // TODO:
    // as a simplified first implementation, the Settings class will not be exposed and the queue elements
    // will be assumed to be logstash Event.


    @JRubyClass(name = "AckedQueue", parent = "Object")
    public static class RubyAckedQueue extends RubyObject {
        Queue queue;

        public RubyAckedQueue(Ruby runtime, RubyClass klass) {
            super(runtime, klass);
        }

        Queue getQueue() {
            return this.queue;
        }

        // def initialize(data = {})
        @JRubyMethod(name = "initialize", required = 2)
        public IRubyObject ruby_initialize(ThreadContext context, RubyString dirPath, RubyNumeric rubyCapacity)
        {

            int capacity = RubyNumeric.num2int(rubyCapacity);

            Settings s = new MemorySettings(dirPath.asJavaString());
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

        @JRubyMethod(name = "write", required = 1)
        public IRubyObject ruby_append(ThreadContext context, IRubyObject event)
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
        public IRubyObject ruby_read_batch(ThreadContext context, RubyNumeric limit, RubyNumeric timeout)
        {
            Batch b;

            try {
                b = this.queue.readBatch(RubyNumeric.num2int(limit), RubyNumeric.num2int(timeout));
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
