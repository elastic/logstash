package org.logstash.ext;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.java.proxies.MapJavaProxy;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.ConvertedMap;
import org.logstash.Event;
import org.logstash.FieldReference;
import org.logstash.RubyUtil;
import org.logstash.Rubyfier;
import org.logstash.Valuefier;

public final class JrubyEventExtLibrary {

    @JRubyClass(name = "Event")
    public static final class RubyEvent extends RubyObject {

        private static final long serialVersionUID = 1L;

        /**
         * Sequence number generator, for generating {@link RubyEvent#hash}.
         */
        private static final AtomicLong SEQUENCE_GENERATOR = new AtomicLong(1L);

        /**
         * Hashcode of this instance. Used to avoid the more expensive {@link RubyObject#hashCode()}
         * since we only care about reference equality for this class anyway.
         */
        private final int hash = nextHash();

        private Event event;

        public RubyEvent(final Ruby runtime, final RubyClass klass) {
            super(runtime, klass);
        }

        public static RubyEvent newRubyEvent(Ruby runtime, Event event) {
            final RubyEvent ruby =
                new RubyEvent(runtime, RubyUtil.RUBY_EVENT_CLASS);
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
                this.event = new Event(
                    ConvertedMap.newFromRubyHash(context, (RubyHash) data)
                );
            } else {
                initializeFallback(context, data);
            }
            return context.nil;
        }

        @JRubyMethod(name = "get", required = 1)
        public IRubyObject ruby_get_field(ThreadContext context, RubyString reference)
        {
            return Rubyfier.deep(
                context.runtime,
                this.event.getUnconvertedField(FieldReference.from(reference.getByteList()))
            );
        }

        @JRubyMethod(name = "set", required = 2)
        public IRubyObject ruby_set_field(ThreadContext context, RubyString reference, IRubyObject value)
        {
            final FieldReference r = FieldReference.from(reference.getByteList());
            if (r.equals(FieldReference.TIMESTAMP_REFERENCE)) {
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
        public IRubyObject ruby_includes(ThreadContext context, RubyString reference) {
            return RubyBoolean.newBoolean(
                context.runtime, this.event.includes(FieldReference.from(reference.getByteList()))
            );
        }

        @JRubyMethod(name = "remove", required = 1)
        public IRubyObject ruby_remove(ThreadContext context, RubyString reference) {
            return Rubyfier.deep(
                context.runtime,
                this.event.remove(FieldReference.from(reference.getByteList()))
            );
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
                throw new RaiseException(getRuntime(), RubyUtil.LOGSTASH_ERROR, "timestamp field is missing", true);
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
            Map<String, Object> data = this.event.toMap();
            Map<String, Object> metadata = this.event.getMetadata();

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
                throw new RaiseException(context.runtime, RubyUtil.GENERATOR_ERROR, e.getMessage(), true);
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
                throw new RaiseException(context.runtime, RubyUtil.PARSER_ERROR, e.getMessage(), true);
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
        public IRubyObject ruby_timestamp(ThreadContext context) {
            // We can just cast to IRubyObject here, because we know that Event stores a
            // RubyTimestamp internally.
            return (IRubyObject) event.getUnconvertedField(FieldReference.TIMESTAMP_REFERENCE);
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

        @Override
        public int hashCode() {
            return hash;
        }

        @Override
        public boolean equals(final Object that) {
            return this == that;
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
                    (Map<String, Object>)((MapJavaProxy)data).getObject())
                );
            } else {
                throw context.runtime.newTypeError("wrong argument type " + data.getMetaClass() + " (expected Hash)");
            }
        }

        private void setEvent(Event event) {
            this.event = event;
        }

        /**
         * Generates a fixed hashcode.
         * @return HashCode value
         */
        private static int nextHash() {
            final long sequence = SEQUENCE_GENERATOR.incrementAndGet();
            return (int) (sequence ^ sequence >>> 32) + 31;
        }
    }
}
