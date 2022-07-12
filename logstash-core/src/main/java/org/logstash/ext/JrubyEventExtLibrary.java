/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.ext;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

import co.elastic.logstash.api.EventFactory;

import org.jruby.Ruby;
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
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import org.logstash.ConvertedMap;
import org.logstash.Event;
import org.logstash.FieldReference;
import org.logstash.RubyUtil;
import org.logstash.Rubyfier;
import org.logstash.Valuefier;
import org.logstash.plugins.BasicEventFactory;

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

        private transient Event event;

        public RubyEvent(final Ruby runtime, final RubyClass klass) {
            super(runtime, klass);
        }

        public static RubyEvent newRubyEvent(Ruby runtime) {
            return newRubyEvent(runtime, new Event());
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
            } else if (data != null && data.getJavaClass().equals(Event.class)) {
                this.event = data.toJava(Event.class);
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
                this.event.getUnconvertedField(extractFieldReference(reference))
            );
        }

        @JRubyMethod(name = "set", required = 2)
        public IRubyObject ruby_set_field(ThreadContext context, RubyString reference, IRubyObject value)
        {
            final FieldReference r = extractFieldReference(reference);
            if (r.equals(FieldReference.TIMESTAMP_REFERENCE)) {
                if (!(value instanceof JrubyTimestampExtLibrary.RubyTimestamp)) {
                    throw context.runtime.newTypeError("wrong argument type " + value.getMetaClass() + " (expected LogStash::Timestamp)");
                }
                this.event.setTimestamp(((JrubyTimestampExtLibrary.RubyTimestamp)value).getTimestamp());
            } else {
                this.event.setField(r, safeValueifierConvert(value));
            }
            return value;
        }

        @JRubyMethod(name = "cancel")
        public IRubyObject ruby_cancel(ThreadContext context)
        {
            this.event.cancel();
            return context.tru;
        }

        @JRubyMethod(name = "uncancel")
        public IRubyObject ruby_uncancel(ThreadContext context)
        {
            this.event.uncancel();
            return context.fals;
        }

        @JRubyMethod(name = "cancelled?")
        public IRubyObject ruby_cancelled(ThreadContext context)
        {
            return RubyBoolean.newBoolean(context.runtime, this.event.isCancelled());
        }

        @JRubyMethod(name = "include?", required = 1)
        public IRubyObject ruby_includes(ThreadContext context, RubyString reference) {
            return RubyBoolean.newBoolean(
                context.runtime, this.event.includes(extractFieldReference(reference))
            );
        }

        @JRubyMethod(name = "remove", required = 1)
        public IRubyObject ruby_remove(ThreadContext context, RubyString reference) {
            return Rubyfier.deep(
                context.runtime,
                this.event.remove(extractFieldReference(reference))
            );
        }

        @JRubyMethod(name = "clone")
        public IRubyObject rubyClone(ThreadContext context)
        {
            return rubyClone(context.runtime);
        }

        public RubyEvent rubyClone(Ruby runtime)
        {
            return RubyEvent.newRubyEvent(runtime, this.event.clone());
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
                throw toRubyError(context, RubyUtil.LOGSTASH_ERROR, "timestamp field is missing", e);
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
        public IRubyObject ruby_to_java(ThreadContext context) {
            return JavaUtil.convertJavaToUsableRubyObject(context.runtime, this.event);
        }

        @JRubyMethod(name = "to_json", rest = true)
        public IRubyObject ruby_to_json(ThreadContext context, IRubyObject[] args)
        {
            try {
                return RubyString.newString(context.runtime, event.toJson());
            } catch (Exception e) {
                throw toRubyError(context, RubyUtil.GENERATOR_ERROR, e);
            }
        }

        // @param value [String] the json string. A json object/map will newFromRubyArray to an array containing a single Event.
        // and a json array will newFromRubyArray each element into individual Event
        // @return Array<Event> array of events
        @JRubyMethod(name = "from_json", required = 1, meta = true)
        public static IRubyObject ruby_from_json(ThreadContext context, IRubyObject recv, RubyString value, final Block block) {
            if (!block.isGiven()) return fromJson(context, value, BasicEventFactory.INSTANCE);
            return fromJson(context, value, (data) -> {
                // LogStash::Event works fine with a Map arg (instead of a native Hash)
                IRubyObject event = block.yield(context, RubyUtil.toRubyObject(data));
                return ((RubyEvent) event).getEvent(); // we unwrap just to re-wrap later
            });
        }

        private static IRubyObject fromJson(ThreadContext context, RubyString json, EventFactory eventFactory) {
            Event[] events;
            try {
                events = Event.fromJson(json.asJavaString(), eventFactory);
            } catch (Exception e) {
                throw toRubyError(context, RubyUtil.PARSER_ERROR, e);
            }

            if (events.length == 1) {
                // micro optimization for the 1 event more common use-case.
                return context.runtime.newArray(RubyEvent.newRubyEvent(context.runtime, events[0]));
            }

            IRubyObject[] rubyEvents = new IRubyObject[events.length];
            for (int i = 0; i < events.length; i++) {
                rubyEvents[i] = RubyEvent.newRubyEvent(context.runtime, events[i]);
            }
            return context.runtime.newArrayNoCopy(rubyEvents);
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
        @SuppressWarnings("unchecked")
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

        /**
         * Shared logic to wrap {@link FieldReference.IllegalSyntaxException}s that are raised by
         * {@link FieldReference#from(RubyString)} when encountering illegal syntax in a ruby-exception
         * that can be easily handled within the ruby plugins
         *
         * @param reference a {@link RubyString} representing the path to a field
         * @return the corresponding {@link FieldReference} (see: {@link FieldReference#from(RubyString)})
         */
        private static FieldReference extractFieldReference(final RubyString reference) {
            try {
                return FieldReference.from(reference);
            } catch (FieldReference.IllegalSyntaxException ise) {
                throw RubyUtil.RUBY.newRuntimeError(ise.getMessage());
            }
        }

        /**
         * Shared logic to wrap {@link FieldReference.IllegalSyntaxException}s that are raised by
         * {@link Valuefier#convert(Object)} when encountering illegal syntax in a ruby-exception
         * that can be easily handled within the ruby plugins
         *
         * @param value a {@link Object} to be passed to {@link Valuefier#convert(Object)}
         * @return the resulting {@link Object} (see: {@link Valuefier#convert(Object)})
         */
        private static Object safeValueifierConvert(final Object value) {
            try {
                return Valuefier.convert(value);
            } catch (FieldReference.IllegalSyntaxException ise) {
                throw RubyUtil.RUBY.newRuntimeError(ise.getMessage());
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

        private static RaiseException toRubyError(ThreadContext context, RubyClass type, Exception e) {
            return toRubyError(context, type, e.getMessage(), e);
        }

        private static RaiseException toRubyError(ThreadContext context, RubyClass type, String message, Exception e) {
            RaiseException ex = RaiseException.from(context.runtime, type, message);
            ex.initCause(e);
            return ex;
        }

    }
}
