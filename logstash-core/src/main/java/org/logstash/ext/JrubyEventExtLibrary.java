package org.logstash.ext;

import java.io.IOException;
import java.util.Map;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.java.proxies.MapJavaProxy;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.Library;
import org.logstash.ConvertedMap;
import org.logstash.Event;
import org.logstash.PathCache;
import org.logstash.Rubyfier;
import org.logstash.Valuefier;

public class JrubyEventExtLibrary implements Library {

    private static RubyClass PARSER_ERROR = null;
    private static RubyClass GENERATOR_ERROR = null;
    private static RubyClass LOGSTASH_ERROR = null;

    @Override
    public void load(Ruby runtime, boolean wrap) throws IOException {
        RubyModule module = runtime.defineModule("LogStash");

        RubyClass clazz = runtime.defineClassUnder(
            "Event", runtime.getObject(), RubyEvent::new, module
        );

        clazz.setConstant("METADATA", runtime.newString(Event.METADATA));
        clazz.setConstant("METADATA_BRACKETS", runtime.newString(Event.METADATA_BRACKETS));
        clazz.setConstant("TIMESTAMP", runtime.newString(Event.TIMESTAMP));
        clazz.setConstant("TIMESTAMP_FAILURE_TAG", runtime.newString(Event.TIMESTAMP_FAILURE_TAG));
        clazz.setConstant("TIMESTAMP_FAILURE_FIELD", runtime.newString(Event.TIMESTAMP_FAILURE_FIELD));
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

    @JRubyClass(name = "Event")
    public static final class RubyEvent extends RubyObject {
        private Event event;

        private RubyEvent(Ruby runtime, RubyClass klass) {
            super(runtime, klass);
        }

        public static RubyEvent newRubyEvent(Ruby runtime, Event event) {
            final RubyEvent ruby =
                new RubyEvent(runtime, runtime.getModule("LogStash").getClass("Event"));
            ruby.setEvent(event);
            return ruby;
        }

        public Event getEvent() {
            return event;
        }

        // def initialize(data = {})
        @JRubyMethod(name = "initialize", optional = 1)
        public IRubyObject ruby_initialize(ThreadContext context, IRubyObject[] args) {
            final IRubyObject data = args.length > 0 ? args[0] : null;
            if (data instanceof RubyHash) {
                this.event = new Event(ConvertedMap.newFromRubyHash((RubyHash) data));
            } else {
                initializeFallback(context, data);
            }
            return context.nil;
        }

        @JRubyMethod(name = "get", required = 1)
        public IRubyObject ruby_get_field(ThreadContext context, RubyString reference)
        {
            Object value = this.event.getUnconvertedField(reference.asJavaString());
            return Rubyfier.deep(context.runtime, value);
        }

        @JRubyMethod(name = "set", required = 2)
        public IRubyObject ruby_set_field(ThreadContext context, RubyString reference, IRubyObject value)
        {
            String r = reference.asJavaString();

            if (PathCache.isTimestamp(r)) {
                if (!(value instanceof JrubyTimestampExtLibrary.RubyTimestamp)) {
                    throw context.runtime.newTypeError("wrong argument type " + value.getMetaClass() + " (expected LogStash::Timestamp)");
                }
                this.event.setTimestamp(((JrubyTimestampExtLibrary.RubyTimestamp)value).getTimestamp());
            } else {
                this.event.setField(r, Valuefier.convert(value));
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

            this.event.append(((RubyEvent) value).getEvent());

            return this;
        }

        @JRubyMethod(name = "sprintf", required = 1)
        public IRubyObject ruby_sprintf(ThreadContext context, IRubyObject format) {
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
        public IRubyObject ruby_to_hash(ThreadContext context) {
            return Rubyfier.deep(context.runtime, this.event.getData());
        }

        @JRubyMethod(name = "to_hash_with_metadata")
        public IRubyObject ruby_to_hash_with_metadata(ThreadContext context) {
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

        // @param value [String] the json string. A json object/map will newFromRubyArray to an array containing a single Event.
        // and a json array will newFromRubyArray each element into individual Event
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
            //TODO(guy) should these tags be BiValues?
            this.event.tag(value.asJavaString());
            return context.nil;
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

        /**
         * Cold path for the Ruby constructor
         * {@link JrubyEventExtLibrary.RubyEvent#ruby_initialize(ThreadContext, IRubyObject[])} for
         * when its argument is not a {@link RubyHash}.
         * @param context Ruby {@link ThreadContext}
         * @param data Either {@code null}, {@link org.jruby.RubyNil} or an instance of
         * {@link MapJavaProxy}
         */
        private void initializeFallback(final ThreadContext context, final IRubyObject data) {
            if (data == null || data.isNil()) {
                this.event = new Event();
            } else if (data instanceof MapJavaProxy) {
                this.event = new Event(ConvertedMap.newFromMap(
                    (Map)((MapJavaProxy)data).getObject())
                );
            } else {
                throw context.runtime.newTypeError("wrong argument type " + data.getMetaClass() + " (expected Hash)");
            }
        }

        private void setEvent(Event event) {
            this.event = event;
        }
    }
}
