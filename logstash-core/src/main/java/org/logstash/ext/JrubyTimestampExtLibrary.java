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

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyComparable;
import org.jruby.RubyFixnum;
import org.jruby.RubyFloat;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.RubyTime;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.ObjectMappers;
import org.logstash.RubyUtil;
import org.logstash.Timestamp;

public final class JrubyTimestampExtLibrary {

    @JRubyClass(name = "Timestamp", include = "Comparable")
    @JsonSerialize(using = ObjectMappers.RubyTimestampSerializer.class)
    public static final class RubyTimestamp extends RubyObject {

        private static final long serialVersionUID = 1L;

        private transient Timestamp timestamp;

        public RubyTimestamp(Ruby runtime, RubyClass klass) {
            super(runtime, klass);
        }

        public static RubyTimestamp newRubyTimestamp(Ruby runtime, Timestamp timestamp) {
            final RubyTimestamp stamp = new RubyTimestamp(runtime, RubyUtil.RUBY_TIMESTAMP_CLASS);
            stamp.timestamp = timestamp;
            return stamp;
        }

        public Timestamp getTimestamp() {
            return timestamp;
        }

        public void setTimestamp(Timestamp timestamp) {
            this.timestamp = timestamp;
        }

        public java.time.Instant toInstant() {
            return this.timestamp.toInstant();
        }

        // def initialize(time = Time.new)
        @JRubyMethod(optional = 1)
        public JrubyTimestampExtLibrary.RubyTimestamp initialize(final ThreadContext context,
            IRubyObject[] args) {
            args = Arity.scanArgs(context.runtime, args, 0, 1);
            IRubyObject time = args[0];

            if (time.isNil()) {
                this.timestamp = new Timestamp();
            } else if (time instanceof RubyTime) {
                this.timestamp = new Timestamp(((RubyTime) time).toInstant());
            } else if (time instanceof RubyString) {
                try {
                    this.timestamp = new Timestamp(time.toString());
                } catch (IllegalArgumentException e) {
                    throw RaiseException.from(
                        getRuntime(), RubyUtil.TIMESTAMP_PARSER_ERROR,
                        "invalid timestamp string format " + time
                    );

                }
            } else {
                throw context.runtime.newTypeError("wrong argument type " + time.getMetaClass() + " (expected Time)");
            }
            return this;
        }

        @JRubyMethod(name = "time")
        public RubyTime ruby_time(ThreadContext context)
        {
            final org.joda.time.DateTime milliPrecise = org.joda.time.Instant.ofEpochMilli(this.timestamp.toEpochMilli()).toDateTime();
            final long excessNanos = Math.floorMod(this.timestamp.nsec(), 1_000_000L);

            return RubyTime.newTime(context.runtime, milliPrecise, excessNanos);
        }

        @JRubyMethod(name = "to_i")
        public IRubyObject ruby_to_i(ThreadContext context)
        {
            return RubyFixnum.newFixnum(context.runtime, this.timestamp.toInstant().getEpochSecond());
        }

        @JRubyMethod(name = "to_f")
        public IRubyObject ruby_to_f(ThreadContext context)
        {
            final java.time.Instant instant = this.timestamp.toInstant();

            final double epochSecondsWithNanos = instant.getEpochSecond() + (instant.getNano() / 1_000_000_000d);

            return RubyFloat.newFloat(context.runtime, epochSecondsWithNanos);
        }

        @JRubyMethod(name = "to_s")
        public IRubyObject ruby_to_s(ThreadContext context)
        {
            return ruby_to_iso8601(context);
        }

        @JRubyMethod(name = "inspect")
        public IRubyObject ruby_inspect(ThreadContext context)
        {
            return ruby_to_iso8601(context);
        }

        @JRubyMethod(name = "to_iso8601")
        public IRubyObject ruby_to_iso8601(ThreadContext context)
        {
            return RubyString.newString(context.runtime, this.timestamp.toString());
        }

        @JRubyMethod(name = "to_java")
        public IRubyObject ruby_to_java(ThreadContext context)
        {
            return JavaUtil.convertJavaToUsableRubyObject(context.runtime, this.timestamp);
        }

        @JRubyMethod(name = "clone")
        public IRubyObject ruby_clone(ThreadContext context) {
            return RubyTimestamp.newRubyTimestamp(context.runtime, this.timestamp);
        }

        @JRubyMethod(name = "dup")
        public IRubyObject ruby_dup(ThreadContext context) {
            return ruby_clone(context);
        }

        @JRubyMethod(name = "to_json", rest = true)
        public IRubyObject ruby_to_json(ThreadContext context, IRubyObject[] args)
        {
            return RubyString.newString(context.runtime,  "\"" + this.timestamp.toString() + "\"");
        }

        @JRubyMethod(name = "coerce", meta = true)
        public static IRubyObject ruby_coerce(ThreadContext context, IRubyObject recv, IRubyObject time)
        {
            try {
                if (time instanceof RubyTimestamp) {
                    return time;
                } else if (time instanceof RubyTime) {
                    return RubyTimestamp.newRubyTimestamp(
                        context.runtime,
                        new Timestamp(((RubyTime) time).toInstant())
                    );
                } else if (time instanceof RubyString) {
                    return fromRString(context.runtime, (RubyString) time);
                } else {
                    return context.runtime.getNil();
                }
             } catch (IllegalArgumentException e) {
                throw RaiseException.from(
                        context.runtime, RubyUtil.TIMESTAMP_PARSER_ERROR,
                        "invalid timestamp format " + e.getMessage()
                );

            }
         }

        @JRubyMethod(name = "parse_iso8601", meta = true)
        public static IRubyObject ruby_parse_iso8601(ThreadContext context, IRubyObject recv, IRubyObject time)
        {
            if (time instanceof RubyString) {
                try {
                    return fromRString(context.runtime, (RubyString) time);
                } catch (IllegalArgumentException e) {
                    throw RaiseException.from(
                            context.runtime, RubyUtil.TIMESTAMP_PARSER_ERROR,
                            "invalid timestamp format " + e.getMessage()
                    );

                }
            } else {
                throw context.runtime.newTypeError("wrong argument type " + time.getMetaClass() + " (expected String)");
            }
        }

        @JRubyMethod(name = "at", required = 1, optional = 1, meta = true)
        public static JrubyTimestampExtLibrary.RubyTimestamp ruby_at(ThreadContext context,
            IRubyObject recv, IRubyObject[] args) {
            RubyTime t;
            if (args.length == 1) {
                // JRuby 9K has fixed the problem iwth BigDecimal precision see https://github.com/elastic/logstash/issues/4565
                t = (RubyTime)RubyTime.at(context, context.runtime.getTime(), args[0]);
            } else {
                t = (RubyTime)RubyTime.at(context, context.runtime.getTime(), args[0], args[1]);
            }
            return RubyTimestamp.newRubyTimestamp(context.runtime, new Timestamp(t.toInstant()));
        }

        @JRubyMethod(name = "now", meta = true)
        public static JrubyTimestampExtLibrary.RubyTimestamp ruby_now(ThreadContext context,
            IRubyObject recv) {
            return RubyTimestamp.newRubyTimestamp(context.runtime, new Timestamp());
        }

        @JRubyMethod(name = "utc")
        public IRubyObject ruby_utc()
        {
            return this;
        }

        @JRubyMethod(name = "gmtime")
        public IRubyObject ruby_gmtime()
        {
            return this;
        }

        @JRubyMethod(name = {"usec", "tv_usec"})
        public IRubyObject ruby_usec(ThreadContext context)
        {
            return RubyFixnum.newFixnum(context.runtime, this.timestamp.usec());
        }

        @JRubyMethod(name = {"nsec", "tv_nsec"})
        public org.jruby.RubyInteger ruby_nsec(final ThreadContext context) {
            return RubyFixnum.newFixnum(context.runtime, this.timestamp.nsec());
        }

        @JRubyMethod(name = "year")
        public IRubyObject ruby_year(ThreadContext context)
        {
            final int year = this.timestamp.toInstant().atOffset(java.time.ZoneOffset.UTC).getYear();
            return RubyFixnum.newFixnum(context.runtime, year);
        }

        @JRubyMethod(name = "<=>")
        public IRubyObject op_cmp(final ThreadContext context, final IRubyObject other) {
            if (other instanceof JrubyTimestampExtLibrary.RubyTimestamp) {
                final int cmp = this.timestamp.compareTo(((RubyTimestamp) other).timestamp);
                return RubyFixnum.newFixnum(context.runtime, cmp);
            }
            return context.nil;
        }

        @JRubyMethod(name = ">=")
        public IRubyObject op_ge(final ThreadContext context, final IRubyObject other) {
            if (other instanceof JrubyTimestampExtLibrary.RubyTimestamp) {
                return context.runtime.newBoolean(compare(context, other) >= 0);
            }
            return RubyComparable.op_ge(context, this, other);
        }

        @JRubyMethod(name = ">")
        public IRubyObject op_gt(final ThreadContext context, final IRubyObject other) {
            if (other instanceof JrubyTimestampExtLibrary.RubyTimestamp) {
                return context.runtime.newBoolean(compare(context, other) > 0);
            }
            return RubyComparable.op_gt(context, this, other);
        }

        @JRubyMethod(name = "<=")
        public IRubyObject op_le(final ThreadContext context, final IRubyObject other) {
            if (other instanceof JrubyTimestampExtLibrary.RubyTimestamp) {
                return context.runtime.newBoolean(compare(context, other) <= 0);
            }
            return RubyComparable.op_le(context, this, other);
        }

        @JRubyMethod(name = "<")
        public IRubyObject op_lt(final ThreadContext context, final IRubyObject other) {
            if (other instanceof JrubyTimestampExtLibrary.RubyTimestamp) {
                return context.runtime.newBoolean(compare(context, other) < 0);
            }
            return RubyComparable.op_lt(context, this, other);
        }

        @JRubyMethod(name = {"eql?", "=="})
        public IRubyObject eql(final ThreadContext context, final IRubyObject other) {
            return this == other || other.getClass() == JrubyTimestampExtLibrary.RubyTimestamp.class
                && timestamp.equals(((JrubyTimestampExtLibrary.RubyTimestamp) other).timestamp)
                ? context.tru : context.fals;
        }

        @JRubyMethod(name = "+")
        public IRubyObject plus(final ThreadContext context, final IRubyObject val) {
            return this.ruby_time(context).callMethod(context, "+", val);
        }

        @JRubyMethod(name = "-")
        public IRubyObject minus(final ThreadContext context, final IRubyObject val) {
            return this.ruby_time(context).callMethod(
                context, "-",
                val instanceof RubyTimestamp ? ((RubyTimestamp)val).ruby_time(context) : val
            );
        }

        private int compare(final ThreadContext context, final IRubyObject other) {
            return op_cmp(context, other).convertToInteger().getIntValue();
        }

        private static RubyTimestamp fromRString(final Ruby runtime, final RubyString string) {
            return RubyTimestamp.newRubyTimestamp(runtime, new Timestamp(string.toString()));
        }
    }
}
