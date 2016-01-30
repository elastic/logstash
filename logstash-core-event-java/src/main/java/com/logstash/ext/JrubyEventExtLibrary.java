package com.logstash.ext;

import com.logstash.Logger;
import com.logstash.Event;
import com.logstash.PathCache;
import com.logstash.Javafier;
import com.logstash.Timestamp;
import com.logstash.Rubyfier;
import com.logstash.Javafier;
import org.jruby.Ruby;
import org.jruby.RubyObject;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyString;
import org.jruby.RubyHash;
import org.jruby.RubyBoolean;
import org.jruby.RubyArray;
import org.jruby.RubyFloat;
import org.jruby.RubyInteger;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.Library;
import org.jruby.ext.bigdecimal.RubyBigDecimal;
import java.io.IOException;
import java.util.Map;
import java.util.HashMap;
import java.util.List;


public class JrubyEventExtLibrary implements Library {

    private static RubyClass PARSER_ERROR = null;
    private static RubyClass GENERATOR_ERROR = null;
    private static RubyClass LOGSTASH_ERROR = null;

    public void load(Ruby runtime, boolean wrap) throws IOException {
        RubyModule module = runtime.defineModule("LogStash");

        RubyClass clazz = runtime.defineClassUnder("Event", runtime.getObject(), new ObjectAllocator() {
            public IRubyObject allocate(Ruby runtime, RubyClass rubyClass) {
                return new RubyEvent(runtime, rubyClass);
            }
        }, module);

        clazz.setConstant("METADATA", runtime.newString(Event.METADATA));
        clazz.setConstant("METADATA_BRACKETS", runtime.newString(Event.METADATA_BRACKETS));
        clazz.setConstant("TIMESTAMP", runtime.newString(Event.TIMESTAMP));
        clazz.setConstant("TIMESTAMP_FAILURE_TAG", runtime.newString(Event.TIMESTAMP_FAILURE_TAG));
        clazz.setConstant("TIMESTAMP_FAILURE_FIELD", runtime.newString(Event.TIMESTAMP_FAILURE_FIELD));
        clazz.setConstant("DEFAULT_LOGGER", runtime.getModule("Cabin").getClass("Channel").callMethod("get", runtime.getModule("LogStash")));
        clazz.setConstant("VERSION", runtime.newString(Event.VERSION));
        clazz.setConstant("VERSION_ONE", runtime.newString(Event.VERSION_ONE));
        clazz.defineAnnotatedMethods(RubyEvent.class);
        clazz.defineAnnotatedConstants(RubyEvent.class);

        PARSER_ERROR = runtime.getModule("LogStash").defineOrGetModuleUnder("Json").getClass("ParserError");
        if (PARSER_ERROR == null) {
            throw new RaiseException(runtime, runtime.getClass("StandardError"), "Could not find LogStash::Json::ParserError class", true);
        }
        GENERATOR_ERROR = runtime.getModule("LogStash").defineOrGetModuleUnder("Json").getClass("GeneratorError");
        if (GENERATOR_ERROR == null) {
            throw new RaiseException(runtime, runtime.getClass("StandardError"), "Could not find LogStash::Json::GeneratorError class", true);
        }
        LOGSTASH_ERROR = runtime.getModule("LogStash").getClass("Error");
        if (LOGSTASH_ERROR == null) {
            throw new RaiseException(runtime, runtime.getClass("StandardError"), "Could not find LogStash::Error class", true);
        }
    }

    public static class ProxyLogger implements Logger {
        private RubyObject logger;

        public ProxyLogger(RubyObject logger) {
             this.logger = logger;
        }

        // TODO: (colin) complete implementation beyond warn when needed

        public void warn(String message) {
            logger.callMethod("warn", RubyString.newString(logger.getRuntime(), message));
        }
    }

    @JRubyClass(name = "Event", parent = "Object")
    public static class RubyEvent extends RubyObject {
        private Event event;
        private static RubyObject logger;

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

            if (data == null || data.isNil()) {
                this.event = new Event();
            } else if (data instanceof RubyHash) {
                HashMap<String, Object>  newObj = Javafier.deep((RubyHash) data);
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
            Object value = this.event.getField(reference.asJavaString());
            return Rubyfier.deep(context.runtime, value);
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
                this.event.setField(r, Javafier.deep(value));
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
            return Rubyfier.deep(context.runtime, this.event.remove(reference.asJavaString()));
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
                throw new RaiseException(getRuntime(), LOGSTASH_ERROR, "timestamp field is missing", true);
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
            return Rubyfier.deep(context.runtime, this.event.toMap());
        }

        @JRubyMethod(name = "to_hash_with_metadata")
        public IRubyObject ruby_to_hash_with_metadata(ThreadContext context) throws IOException
        {
            Map data = this.event.toMap();
            Map metadata = this.event.getMetadata();

            if (!metadata.isEmpty()) {
                data.put(Event.METADATA, metadata);
            }
            return Rubyfier.deep(context.runtime, data);
        }

        @JRubyMethod(name = "to_java")
        public IRubyObject ruby_to_java(ThreadContext context)
        {
            return JavaUtil.convertJavaToUsableRubyObject(context.runtime, this.event);
        }

        @JRubyMethod(name = "to_json", rest = true)
        public IRubyObject ruby_to_json(ThreadContext context, IRubyObject[] args)
        {
            try {
                return RubyString.newString(context.runtime, event.toJson());
            } catch (Exception e) {
                throw new RaiseException(context.runtime, GENERATOR_ERROR, e.getMessage(), true);
            }
        }

        // @param value [String] the json string. A json object/map will convert to an array containing a single Event.
        // and a json array will convert each element into individual Event
        // @return Array<Event> array of events
        @JRubyMethod(name = "from_json", required = 1, meta = true)
        public static IRubyObject ruby_from_json(ThreadContext context, IRubyObject recv, RubyString value)
        {
            Event[] events;
            try {
                events = Event.fromJson(value.asJavaString());
            } catch (Exception e) {
                throw new RaiseException(context.runtime, PARSER_ERROR, e.getMessage(), true);
            }

            RubyArray result = RubyArray.newArray(context.runtime, events.length);

            if (events.length == 1) {
                // micro optimization for the 1 event more common use-case.
                result.set(0, RubyEvent.newRubyEvent(context.runtime, events[0]));
            } else {
                for (int i = 0; i < events.length; i++) {
                    result.set(i, RubyEvent.newRubyEvent(context.runtime, events[i]));
                }
            }
            return result;
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

        @JRubyMethod(name = "timestamp=", required = 1)
        public IRubyObject ruby_set_timestamp(ThreadContext context, IRubyObject value)
        {
            if (!(value instanceof JrubyTimestampExtLibrary.RubyTimestamp)) {
                throw context.runtime.newTypeError("wrong argument type " + value.getMetaClass() + " (expected LogStash::Timestamp)");
            }
            this.event.setTimestamp(((JrubyTimestampExtLibrary.RubyTimestamp)value).getTimestamp());
            return value;
        }

        // set a new logger for all Event instances
        // there is no point in changing it at runtime for other reasons than in tests/specs.
        @JRubyMethod(name = "logger=", required = 1, meta = true)
        public static IRubyObject ruby_set_logger(ThreadContext context, IRubyObject recv, IRubyObject value)
        {
            Event.setLogger(new ProxyLogger((RubyObject)value));
            return value;
        }
    }
}
