package com.logstash.ext;

import com.logstash.Event;
import com.logstash.EventImpl;
import com.logstash.PathCache;
import com.logstash.Timestamp;
import org.jruby.*;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.java.proxies.MapJavaProxy;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.Library;

import java.io.IOException;
import java.nio.file.Path;
import java.util.*;

public class JrubyEventExtLibrary implements Library {

    public void load(Ruby runtime, boolean wrap) throws IOException {
        RubyModule module = runtime.defineModule("LogStash");
        RubyClass clazz = runtime.defineClassUnder("Event", runtime.getObject(), new ObjectAllocator() {
            public IRubyObject allocate(Ruby runtime, RubyClass rubyClass) {
                return new RubyEvent(runtime, rubyClass);
            }
        }, module);
        clazz.defineAnnotatedMethods(RubyEvent.class);
    }

    @JRubyClass(name = "Event", parent = "Object")
    public static class RubyEvent extends RubyObject {

        private Event event;

        public RubyEvent(Ruby runtime, RubyClass klass) {
            super(runtime, klass);
        }

        public RubyEvent(Ruby runtime) {
            this(runtime, runtime.getModule("LogStash").getClass("Timestamp"));
        }

        public RubyEvent(Ruby runtime, Event event) {
            this(runtime);
            this.event = event;
        }

        public static RubyEvent newRubyEvent(Ruby runtime, Event event) {
            return new RubyEvent(runtime, event);
        }

        public Event getEvent() {
            return event;
        }

        public void setEvent(Event event) {
            this.event = event;
        }

        // def initialize(data = {})
        @JRubyMethod(name = "initialize", optional = 1)
        public IRubyObject ruby_initialize(ThreadContext context, IRubyObject[] args)
        {
            args = Arity.scanArgs(context.runtime, args, 0, 1);
            IRubyObject data = args[0];

            if (data.isNil()) {
                this.event = new EventImpl();
            } else if (data instanceof Map) {
                this.event = new EventImpl((Map)data);
            } else if (Map.class.isAssignableFrom(data.getJavaClass())) {
                this.event = new EventImpl((Map)data.toJava(Map.class));
            } else {
                throw context.runtime.newTypeError("wrong argument type " + data.getMetaClass() + " (expected Hash)");
            }
            return context.nil;
        }

        @JRubyMethod(name = "[]", required = 1)
        public IRubyObject ruby_get_field(ThreadContext context, RubyString reference)
        {
            String r = reference.asJavaString();
            if (PathCache.getInstance().isTimestamp(r)) {
                return JrubyTimestampExtLibrary.RubyTimestamp.newRubyTimestamp(context.runtime, this.event.getTimestamp());
            } else {
                Object value = this.event.getField(r);
                if (value instanceof Timestamp) {
                    return JrubyTimestampExtLibrary.RubyTimestamp.newRubyTimestamp(context.runtime, (Timestamp)value);
                } else {
                    return JavaUtil.convertJavaToRuby(context.runtime, value);
                }
            }
        }

        @JRubyMethod(name = "[]=", required = 2)
        public IRubyObject ruby_set_field(ThreadContext context, RubyString reference, IRubyObject value)
        {
            String r = reference.asJavaString();
            if (PathCache.getInstance().isTimestamp(r)) {
                if (!(value instanceof JrubyTimestampExtLibrary.RubyTimestamp)) {
                    throw context.runtime.newTypeError("wrong argument type " + value.getMetaClass() + " (expected LogStash::Timestamp)");
                }
                this.event.setTimestamp(((JrubyTimestampExtLibrary.RubyTimestamp)value).getTimestamp());
            } else {
                if (value instanceof RubyString) {
                    this.event.setField(r, ((RubyString) value).asJavaString());
                } else if (value instanceof RubyInteger) {
                    this.event.setField(r, ((RubyInteger) value).getLongValue());
                } else if (value instanceof RubyFloat) {
                    this.event.setField(r, ((RubyFloat) value).getDoubleValue());
                } else if (value instanceof JrubyTimestampExtLibrary.RubyTimestamp) {
                    // RubyTimestamp could be assigned in another field thant @timestamp
                    this.event.setField(r, ((JrubyTimestampExtLibrary.RubyTimestamp) value).getTimestamp());
                }
            }
            return value;
        }

        @JRubyMethod(name = "cancel")
        public IRubyObject ruby_cancel(ThreadContext context)
        {
            this.event.cancel();
            return RubyBoolean.createTrueClass(context.runtime);
        }

        @JRubyMethod(name = "uncancel")
        public IRubyObject ruby_uncancel(ThreadContext context)
        {
            this.event.uncancel();
            return RubyBoolean.createFalseClass(context.runtime);
        }

        @JRubyMethod(name = "cancelled?")
        public IRubyObject ruby_cancelled(ThreadContext context)
        {
            return RubyBoolean.newBoolean(context.runtime, this.event.isCancelled());
        }

        @JRubyMethod(name = "timestamp")
        public IRubyObject ruby_get_timestamp(ThreadContext context)
        {
            return JrubyTimestampExtLibrary.RubyTimestamp.newRubyTimestamp(context.runtime, this.event.getTimestamp());
        }

        @JRubyMethod(name = "timestamp=", required = 1)
        public IRubyObject ruby_set_timestamp(ThreadContext context, IRubyObject timestamp)
        {
            if (!(timestamp instanceof JrubyTimestampExtLibrary.RubyTimestamp)) {
                throw context.runtime.newTypeError("wrong argument type " + timestamp.getMetaClass() + " (expected LogStash::Timestamp)");
            }
            this.event.setTimestamp(((JrubyTimestampExtLibrary.RubyTimestamp)timestamp).getTimestamp());
            return timestamp;
        }

        @JRubyMethod(name = "include?", required = 1)
        public IRubyObject ruby_includes(ThreadContext context, RubyString reference)
        {
            return RubyBoolean.newBoolean(context.runtime, this.event.includes(reference.asJavaString()));
        }

        @JRubyMethod(name = "remove", required = 1)
        public IRubyObject ruby_remove(ThreadContext context, RubyString reference)
        {
            return JavaUtil.convertJavaToRuby(context.runtime, this.event.remove(reference.asJavaString()));
        }

        @JRubyMethod(name = "clone")
        public IRubyObject ruby_clone(ThreadContext context)
        {
            return RubyEvent.newRubyEvent(context.runtime, this.event.clone());
        }

        @JRubyMethod(name = "overwrite", required = 1)
        public IRubyObject ruby_overwrite(ThreadContext context, IRubyObject value)
        {
            if (!(value instanceof RubyEvent)) {
                throw context.runtime.newTypeError("wrong argument type " + value.getMetaClass() + " (expected LogStash::Event)");
            }
            return RubyEvent.newRubyEvent(context.runtime, this.event.overwrite(((RubyEvent) value).event));
        }

        @JRubyMethod(name = "append", required = 1)
        public IRubyObject ruby_append(ThreadContext context, IRubyObject value)
        {
            if (!(value instanceof RubyEvent)) {
                throw context.runtime.newTypeError("wrong argument type " + value.getMetaClass() + " (expected LogStash::Event)");
            }
            return RubyEvent.newRubyEvent(context.runtime, this.event.append(((RubyEvent)value).event));
        }

        @JRubyMethod(name = "sprintf", required = 1)
        public IRubyObject ruby_sprintf(ThreadContext context, IRubyObject format)
        {
            return RubyString.newString(context.runtime, event.sprintf(format.toString()));
        }

        @JRubyMethod(name = "to_s")
        public IRubyObject ruby_to_s(ThreadContext context)
        {
            return RubyString.newString(context.runtime, event.toString());
        }

        @JRubyMethod(name = "to_hash")
        public IRubyObject ruby_to_hash(ThreadContext context)
        {
            // TODO: is this the most efficient?
            RubyHash hash = JavaUtil.convertJavaToUsableRubyObject(context.runtime, this.event.toMap()).convertToHash();
            // inject RubyTimestamp in new hash
            hash.put(PathCache.TIMESTAMP, JrubyTimestampExtLibrary.RubyTimestamp.newRubyTimestamp(context.runtime, this.event.getTimestamp()));
            return hash;
        }

        @JRubyMethod(name = "to_java")
        public IRubyObject ruby_to_java(ThreadContext context)
        {
            return JavaUtil.convertJavaToUsableRubyObject(context.runtime, this.event);
        }

        @JRubyMethod(name = "to_json", rest = true)
        public IRubyObject ruby_to_json(ThreadContext context, IRubyObject[] args)
            throws IOException
        {
            return RubyString.newString(context.runtime, event.toJson());
        }

        @JRubyMethod(name = "validate_value", required = 1, meta = true)
        public static IRubyObject ruby_validate_value(ThreadContext context, IRubyObject recv, IRubyObject value)
        {
            // TODO: add UTF-8 validation
            return value;
        }
    }
}
