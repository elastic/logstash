package com.logstash.ext;

import com.logstash.*;
import org.codehaus.jackson.map.annotate.JsonSerialize;
import org.jruby.*;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.Library;

import java.io.IOException;

public class JrubyTimestampExtLibrary implements Library {
    public void load(Ruby runtime, boolean wrap) throws IOException {
        RubyModule module = runtime.defineModule("LogStash");
        RubyClass clazz = runtime.defineClassUnder("Timestamp", runtime.getObject(), new ObjectAllocator() {
            public IRubyObject allocate(Ruby runtime, RubyClass rubyClass) {
                return new RubyTimestamp(runtime, rubyClass);
            }
        }, module);
        clazz.defineAnnotatedMethods(RubyTimestamp.class);
    }

    @JRubyClass(name = "Timestamp", parent = "Object")
    public static class RubyTimestamp extends RubyObject {

        private Timestamp timestamp;

        public RubyTimestamp(Ruby runtime, RubyClass klass) {
            super(runtime, klass);
        }

        public RubyTimestamp(Ruby runtime, RubyClass klass, Timestamp timestamp) {
            this(runtime, klass);
            this.timestamp = timestamp;
        }

        public RubyTimestamp(Ruby runtime, Timestamp timestamp) {
            this(runtime, runtime.getModule("LogStash").getClass("Timestamp"), timestamp);
        }

        public RubyTimestamp(Ruby runtime) {
            this(runtime, new Timestamp());
        }

        public static RubyTimestamp newRubyTimestamp(Ruby runtime) {
            return new RubyTimestamp(runtime);
        }

        public static RubyTimestamp newRubyTimestamp(Ruby runtime, long epoch) {
            // Ruby epoch is in seconds, Java in milliseconds
            return new RubyTimestamp(runtime, new Timestamp(epoch * 1000));
        }

        public static RubyTimestamp newRubyTimestamp(Ruby runtime, Timestamp timestamp) {
            return new RubyTimestamp(runtime, timestamp);
        }

        public Timestamp getTimestamp() {
            return timestamp;
        }

        public void setTimestamp(Timestamp timestamp) {
            this.timestamp = timestamp;
        }

        // def initialize(time = Time.new)
        @JRubyMethod(name = "initialize", optional = 1)
        public IRubyObject ruby_initialize(ThreadContext context, IRubyObject[] args)
        {
            args = Arity.scanArgs(context.runtime, args, 0, 1);
            IRubyObject time = args[0];

            if (time.isNil()) {
                this.timestamp = new Timestamp();
            } else if (time instanceof RubyTime) {
                this.timestamp = new Timestamp(((RubyTime)time).getDateTime());
            } else {
                throw context.runtime.newTypeError("wrong argument type " + time.getMetaClass() + " (expected Time)");
            }
            return context.nil;
        }

        @JRubyMethod(name = "time")
        public IRubyObject ruby_time(ThreadContext context)
        {
            return RubyTime.newTime(context.runtime, this.timestamp.getTime());
        }

        @JRubyMethod(name = "to_i")
        public IRubyObject ruby_to_i(ThreadContext context)
        {
            return RubyFixnum.newFixnum(context.runtime, this.timestamp.getTime().getMillis() / 1000);
        }

        @JRubyMethod(name = "to_s")
        public IRubyObject ruby_to_s(ThreadContext context)
        {
            return ruby_to_iso8601(context);
        }

        @JRubyMethod(name = "to_iso8601")
        public IRubyObject ruby_to_iso8601(ThreadContext context)
        {
            return RubyString.newString(context.runtime, this.timestamp.toIso8601());
        }

        @JRubyMethod(name = "to_java")
        public IRubyObject ruby_to_java(ThreadContext context)
        {
            return JavaUtil.convertJavaToUsableRubyObject(context.runtime, this.timestamp);
        }

        @JRubyMethod(name = "to_json", rest = true)
        public IRubyObject ruby_to_json(ThreadContext context, IRubyObject[] args)
        {
            return RubyString.newString(context.runtime,  "\"" + this.timestamp.toIso8601() + "\"");
        }

        @JRubyMethod(name = "at", required = 1, meta = true)
        public static IRubyObject ruby_at(ThreadContext context, IRubyObject recv, IRubyObject epoch)
        {
            if (!(epoch instanceof RubyInteger)) {
                throw context.runtime.newTypeError("wrong argument type " + epoch.getMetaClass() + " (expected integer Fixnum)");
            }
            //
            return RubyTimestamp.newRubyTimestamp(context.runtime, (((RubyInteger) epoch).getLongValue()));
        }

        @JRubyMethod(name = "now", meta = true)
        public static IRubyObject ruby_at(ThreadContext context, IRubyObject recv)
        {
            return RubyTimestamp.newRubyTimestamp(context.runtime);
        }
    }
}
