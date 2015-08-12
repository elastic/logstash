package com.logstash.ext;

import com.logstash.Event;
import com.logstash.PathCache;
import com.logstash.RubyToJavaConverter;
import com.logstash.Timestamp;
import org.jruby.*;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyConstant;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.java.proxies.MapJavaProxy;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.Library;

import java.io.IOException;
import java.util.*;


public class JrubyEventExtLibrary implements Library {

    public void load(Ruby runtime, boolean wrap) throws IOException {
        RubyModule module = runtime.defineModule("LogStash");
        RubyClass clazz = runtime.defineClassUnder("Event", runtime.getObject(), new ObjectAllocator() {
            public IRubyObject allocate(Ruby runtime, RubyClass rubyClass) {
                return new RubyEvent(runtime, rubyClass);
            }
        }, module);
        clazz.setConstant("LOGGER", runtime.getModule("Cabin").getClass("Channel")
                .callMethod("get", runtime.getModule("LogStash")));
        clazz.setConstant("TIMESTAMP", runtime.newString(Event.TIMESTAMP));
        clazz.setConstant("TIMESTAMP_FAILURE_TAG", runtime.newString(Event.TIMESTAMP_FAILURE_TAG));
        clazz.setConstant("TIMESTAMP_FAILURE_FIELD", runtime.newString(Event.TIMESTAMP_FAILURE_FIELD));
        clazz.defineAnnotatedMethods(RubyEvent.class);
        clazz.defineAnnotatedConstants(RubyEvent.class);
    }

    @JRubyClass(name = "Event", parent = "Object")
    public static class RubyEvent extends RubyObject {
        private Event event;

        public RubyEvent(Ruby runtime, RubyClass klass) {
            super(runtime, klass);
        }

        public RubyEvent(Ruby runtime) {
            this(runtime, runtime.getModule("LogStash").getClass("Event"));
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
                this.event = new Event();
            } else if (data instanceof RubyHash) {
                HashMap<String, Object>  newObj = RubyToJavaConverter.convertToMap((RubyHash) data);
                this.event = new Event(newObj);
            } else if (data instanceof Map) {
                this.event = new Event((Map) data);
            } else if (Map.class.isAssignableFrom(data.getJavaClass())) {
                this.event = new Event((Map)data.toJava(Map.class));
            } else {
                throw context.runtime.newTypeError("wrong argument type " + data.getMetaClass() + " (expected Hash)");
            }

            return context.nil;
        }

        @JRubyMethod(name = "[]", required = 1)
        public IRubyObject ruby_get_field(ThreadContext context, RubyString reference)
        {
            String r = reference.asJavaString();
            Object value = this.event.getField(r);
            if (value instanceof Timestamp) {
                return JrubyTimestampExtLibrary.RubyTimestamp.newRubyTimestamp(context.runtime, (Timestamp)value);
            } else if (value instanceof List) {
                IRubyObject obj = JavaUtil.convertJavaToRuby(context.runtime, value);
                return obj.callMethod(context, "to_a");
            } else {
                return JavaUtil.convertJavaToRuby(context.runtime, value);
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
                    String val = ((RubyString) value).asJavaString();
                    this.event.setField(r, val);
                } else if (value instanceof RubyInteger) {
                    this.event.setField(r, ((RubyInteger) value).getLongValue());
                } else if (value instanceof RubyFloat) {
                    this.event.setField(r, ((RubyFloat) value).getDoubleValue());
                } else if (value instanceof JrubyTimestampExtLibrary.RubyTimestamp) {
                    // RubyTimestamp could be assigned in another field thant @timestamp
                    this.event.setField(r, ((JrubyTimestampExtLibrary.RubyTimestamp) value).getTimestamp());
                } else if (value instanceof RubyArray) {
                    this.event.setField(r, RubyToJavaConverter.convertToList((RubyArray) value));
                } else if (value instanceof RubyHash) {
                    this.event.setField(r, RubyToJavaConverter.convertToMap((RubyHash) value));
                } else {
                    throw context.runtime.newTypeError("wrong argument type " + value.getMetaClass());
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
            try {
                return RubyEvent.newRubyEvent(context.runtime, this.event.clone());
            } catch (CloneNotSupportedException e) {
                throw context.runtime.newRuntimeError(e.getMessage());
            }
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

            this.event.append(((RubyEvent) value).getEvent());

            return this;
        }

        @JRubyMethod(name = "sprintf", required = 1)
        public IRubyObject ruby_sprintf(ThreadContext context, IRubyObject format) throws IOException {
            try {
                return RubyString.newString(context.runtime, event.sprintf(format.toString()));
            } catch (IOException e) {
                throw new RaiseException(getRuntime(),
                        (RubyClass) getRuntime().getModule("LogStash").getClass("Error"),
                        "timestamp field is missing", true);
            }
        }

        @JRubyMethod(name = "to_s")
        public IRubyObject ruby_to_s(ThreadContext context)
        {
            return RubyString.newString(context.runtime, event.toString());
        }

        @JRubyMethod(name = "to_hash")
        public IRubyObject ruby_to_hash(ThreadContext context) throws IOException
        {
            // TODO: is this the most efficient?
            RubyHash hash = JavaUtil.convertJavaToUsableRubyObject(context.runtime, this.event.toMap()).convertToHash();
            // inject RubyTimestamp in new hash
            hash.put(PathCache.TIMESTAMP, JrubyTimestampExtLibrary.RubyTimestamp.newRubyTimestamp(context.runtime, this.event.getTimestamp()));
            return hash;
        }

        @JRubyMethod(name = "to_hash_with_metadata")
        public IRubyObject ruby_to_hash_with_metadata(ThreadContext context) throws IOException
        {
            HashMap<String, Object> dataAndMetadata = new HashMap<String, Object>(this.event.getData());
            if (!this.event.getMetadata().isEmpty()) {
                dataAndMetadata.put(Event.METADATA, this.event.getMetadata());
            }

            RubyHash hash = JavaUtil.convertJavaToUsableRubyObject(context.runtime, dataAndMetadata).convertToHash();

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

        @JRubyMethod(name = "tag", required = 1)
        public IRubyObject ruby_tag(ThreadContext context, RubyString value)
        {
            this.event.tag(((RubyString) value).asJavaString());
            return context.runtime.getNil();
        }

        @JRubyMethod(name = "timestamp")
        public IRubyObject ruby_timestamp(ThreadContext context) throws IOException {
            return new JrubyTimestampExtLibrary.RubyTimestamp(context.getRuntime(), this.event.getTimestamp());
        }
    }
}
