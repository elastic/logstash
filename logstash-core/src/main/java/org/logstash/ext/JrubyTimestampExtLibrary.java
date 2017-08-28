package org.logstash.ext;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import java.io.IOException;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyFloat;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.RubyTime;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.Library;
import org.logstash.RubyUtil;
import org.logstash.Timestamp;
import org.logstash.json.RubyTimestampSerializer;

public class JrubyTimestampExtLibrary implements Library {

    private static final ObjectAllocator ALLOCATOR = new ObjectAllocator() {
        public RubyTimestamp allocate(Ruby runtime, RubyClass rubyClass) {
            return new RubyTimestamp(runtime, rubyClass);
        }
    };

    public void load(Ruby runtime, boolean wrap) throws IOException {
        createTimestamp(runtime);
    }

    public static RubyClass createTimestamp(Ruby runtime) {
        RubyModule module = runtime.defineModule(RubyUtil.LS_MODULE_NAME);
        RubyClass clazz = runtime.defineClassUnder("Timestamp", runtime.getObject(), ALLOCATOR, module);
        clazz.defineAnnotatedMethods(RubyTimestamp.class);
        return clazz;
    }

    @JRubyClass(name = "Timestamp")
    @JsonSerialize(using = RubyTimestampSerializer.class)
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
            this(runtime, runtime.getModule(RubyUtil.LS_MODULE_NAME).getClass("Timestamp"), timestamp);
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
            } else if (time instanceof RubyString) {
                try {
                    this.timestamp = new Timestamp(time.toString());
                } catch (IllegalArgumentException e) {
                    throw new RaiseException(
                            getRuntime(),
                            getRuntime().getModule(RubyUtil.LS_MODULE_NAME).getClass("TimestampParserError"),
                            "invalid timestamp string format " + time,
                            true
                    );

                }
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

        @JRubyMethod(name = "to_f")
        public IRubyObject ruby_to_f(ThreadContext context)
        {
            return RubyFloat.newFloat(context.runtime, this.timestamp.getTime().getMillis() / 1000.0d);
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

        @JRubyMethod(name = "coerce", required = 1, meta = true)
        public static IRubyObject ruby_coerce(ThreadContext context, IRubyObject recv, IRubyObject time)
        {
            try {
                if (time instanceof RubyTimestamp) {
                    return time;
                } else if (time instanceof RubyTime) {
                    return RubyTimestamp.newRubyTimestamp(
                        context.runtime,
                        new Timestamp(((RubyTime) time).getDateTime())
                    );
                } else if (time instanceof RubyString) {
                    return fromRString(context.runtime, (RubyString) time);
                } else {
                    return context.runtime.getNil();
                }
             } catch (IllegalArgumentException e) {
                throw new RaiseException(
                        context.runtime,
                        context.runtime.getModule(RubyUtil.LS_MODULE_NAME).getClass("TimestampParserError"),
                        "invalid timestamp format " + e.getMessage(),
                        true
                );

            }
         }

        @JRubyMethod(name = "parse_iso8601", required = 1, meta = true)
        public static IRubyObject ruby_parse_iso8601(ThreadContext context, IRubyObject recv, IRubyObject time)
        {
            if (time instanceof RubyString) {
                try {
                    return fromRString(context.runtime, (RubyString) time);
                } catch (IllegalArgumentException e) {
                    throw new RaiseException(
                            context.runtime,
                            context.runtime.getModule(RubyUtil.LS_MODULE_NAME).getClass("TimestampParserError"),
                            "invalid timestamp format " + e.getMessage(),
                            true
                    );

                }
            } else {
                throw context.runtime.newTypeError("wrong argument type " + time.getMetaClass() + " (expected String)");
            }
        }

        @JRubyMethod(name = "at", required = 1, optional = 1, meta = true)
        public static IRubyObject ruby_at(ThreadContext context, IRubyObject recv, IRubyObject[] args)
        {
            RubyTime t;
            if (args.length == 1) {
                // JRuby 9K has fixed the problem iwth BigDecimal precision see https://github.com/elastic/logstash/issues/4565
                t = (RubyTime)RubyTime.at(context, context.runtime.getTime(), args[0]);
            } else {
                t = (RubyTime)RubyTime.at(context, context.runtime.getTime(), args[0], args[1]);
            }
            return RubyTimestamp.newRubyTimestamp(context.runtime, new Timestamp(t.getDateTime()));
        }

        @JRubyMethod(name = "now", meta = true)
        public static IRubyObject ruby_now(ThreadContext context, IRubyObject recv)
        {
            return RubyTimestamp.newRubyTimestamp(context.runtime);
        }

        @JRubyMethod(name = "utc")
        public IRubyObject ruby_utc(ThreadContext context)
        {
            return this;
        }

        @JRubyMethod(name = "gmtime")
        public IRubyObject ruby_gmtime(ThreadContext context)
        {
            return this;
        }

        @JRubyMethod(name = {"usec", "tv_usec"})
        public IRubyObject ruby_usec(ThreadContext context)
        {
            return RubyFixnum.newFixnum(context.runtime, this.timestamp.usec());
        }

        @JRubyMethod(name = "year")
        public IRubyObject ruby_year(ThreadContext context)
        {
            return RubyFixnum.newFixnum(context.runtime, this.timestamp.getTime().getYear());
        }

        private static RubyTimestamp fromRString(final Ruby runtime, final RubyString string) {
            return RubyTimestamp.newRubyTimestamp(runtime, new Timestamp(string.toString()));
        }
    }
}
