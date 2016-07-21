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
import org.logstash.ackedqueue.Batch;

import java.io.IOException;

public class JrubyAckedBatchExtLibrary implements Library {

    public void load(Ruby runtime, boolean wrap) throws IOException {
        RubyModule module = runtime.defineModule("LogStash");

        RubyClass clazz = runtime.defineClassUnder("AckedBatch", runtime.getObject(), new ObjectAllocator() {
            public IRubyObject allocate(Ruby runtime, RubyClass rubyClass) {
                return new RubyAckedBatch(runtime, rubyClass);
            }
        }, module);
    }

    @JRubyClass(name = "AckedBatch", parent = "Object")
    public static class RubyAckedBatch extends RubyObject {
        Batch batch;

        public RubyAckedBatch(Ruby runtime, RubyClass klass) {
            super(runtime, klass);
        }

        public RubyAckedBatch(Ruby runtime) {
            this(runtime, runtime.getModule("LogStash").getClass("AckedBatch"));
        }

        public RubyAckedBatch(Ruby runtime, Batch batch) {
            this(runtime);
            this.batch = batch;
        }

        // def initialize(data = {})
        @JRubyMethod(name = "initialize", required = 2)
        public IRubyObject ruby_initialize(ThreadContext context, RubyArray events, JrubyAckedQueueExtLibrary.RubyAckedQueue queue)
        {
            this.batch = new Batch(events.getList(), queue.getQueue());

            return context.nil;
        }

        @JRubyMethod(name = "get_elements")
        public IRubyObject ruby_get_elements(ThreadContext context)
        {
            RubyArray result = context.runtime.newArray();
            this.batch.getElements().forEach(e -> result.add(new JrubyEventExtLibrary.RubyEvent(context.runtime, (Event)e)));

            return result;
        }

        @JRubyMethod(name = "close")
        public IRubyObject ruby_close(ThreadContext context)
        {
            try {
                this.batch.close();
            } catch (IOException e) {
                throw context.runtime.newIOErrorFromException(e);
            }

            return context.nil;
        }
    }
}
