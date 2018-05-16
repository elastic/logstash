package org.logstash.log;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyNumeric;
import org.jruby.RubyObject;
import org.jruby.RubySymbol;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;

@JRubyClass(name = "SlowLogger")
public class SlowLoggerExt extends RubyObject {

    private static final RubySymbol PLUGIN_PARAMS = RubyUtil.RUBY.newSymbol("plugin_params");
    private static final RubySymbol TOOK_IN_NANOS = RubyUtil.RUBY.newSymbol("took_in_nanos");
    private static final RubySymbol TOOK_IN_MILLIS = RubyUtil.RUBY.newSymbol("took_in_millis");
    private static final RubySymbol EVENT = RubyUtil.RUBY.newSymbol("event");
    private static final RubyNumeric NANO_TO_MILLI = RubyUtil.RUBY.newFixnum(1000000);

    private Logger slowLogger;
    private long warnThreshold;
    private long infoThreshold;
    private long debugThreshold;
    private long traceThreshold;

    public SlowLoggerExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(required = 5)
    public SlowLoggerExt initialize(final ThreadContext context, final IRubyObject[] args) {
        String loggerName = args[0].asJavaString();
        slowLogger = LogManager.getLogger("slowlog." + loggerName);
        warnThreshold = ((RubyNumeric) args[1]).getLongValue();
        infoThreshold = ((RubyNumeric) args[2]).getLongValue();
        debugThreshold = ((RubyNumeric) args[3]).getLongValue();
        traceThreshold = ((RubyNumeric) args[4]).getLongValue();
        return this;
    }

    private RubyHash asData(final ThreadContext context, final IRubyObject pluginParams,
                            final IRubyObject event, final IRubyObject durationNanos) {
        RubyHash data = RubyHash.newHash(context.runtime);
        data.put(PLUGIN_PARAMS, pluginParams);
        data.put(TOOK_IN_NANOS, durationNanos);
        data.put(TOOK_IN_MILLIS, ((RubyNumeric)durationNanos).div(context, NANO_TO_MILLI));
        data.put(EVENT, event.callMethod(context, "to_json"));
        return data;
    }

    @JRubyMethod(name = "on_event", required = 4)
    public IRubyObject onEvent(final ThreadContext context, final IRubyObject[] args) {
        String message = args[0].asJavaString();
        long eventDurationNanos = ((RubyNumeric)args[3]).getLongValue();

        if (warnThreshold >= 0 && eventDurationNanos > warnThreshold) {
            slowLogger.warn(message, asData(context, args[1], args[2], args[3]));
        } else if (infoThreshold >= 0 && eventDurationNanos > infoThreshold) {
            slowLogger.info(message, asData(context, args[1], args[2], args[3]));
        } else if (debugThreshold >= 0 && eventDurationNanos > debugThreshold) {
            slowLogger.debug(message, asData(context, args[1], args[2], args[3]));
        } else if (traceThreshold >= 0 && eventDurationNanos > traceThreshold) {
            slowLogger.trace(message, asData(context, args[1], args[2], args[3]));
        }
        return context.nil;
    }

}
