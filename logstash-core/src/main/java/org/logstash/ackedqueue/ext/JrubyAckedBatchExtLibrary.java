package org.logstash.ackedqueue.ext;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyArray;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.Library;
import org.logstash.RubyUtil;
import org.logstash.ackedqueue.Batch;
import org.logstash.Event;
import org.logstash.ext.JrubyEventExtLibrary;
import java.io.IOException;

public class JrubyAckedBatchExtLibrary implements Library {

    public void load(Ruby runtime, boolean wrap) throws IOException {
        RubyModule module = runtime.defineModule("LogStash");

        RubyClass clazz = runtime.defineClassUnder("AckedBatch", runtime.getObject(), new ObjectAllocator() {
            public IRubyObject allocate(Ruby runtime, RubyClass rubyClass) {
                return new RubyAckedBatch(runtime, rubyClass);
            }
        }, module);

        clazz.defineAnnotatedMethods(RubyAckedBatch.class);
    }

    @JRubyClass(name = "AckedBatch", parent = "Object")
    public static class RubyAckedBatch extends RubyObject {
        private Batch batch;

        public RubyAckedBatch(Ruby runtime, RubyClass klass) {
            super(runtime, klass);
            this.batch = null;
        }

        public RubyAckedBatch(Ruby runtime, Batch batch) {
            super(runtime, runtime.getModule("LogStash").getClass("AckedBatch"));
            this.batch = batch;
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
                throw RubyUtil.newRubyIOError(context.runtime, e);
            }

            return context.nil;
        }
    }
}
