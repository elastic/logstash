package org.logstash.instrument.metrics;

import org.jruby.RubySymbol;
import org.logstash.RubyUtil;

public final class MetricKeys {

    private MetricKeys() {
        // Constant Holder
    }

    public static final RubySymbol PIPELINES_KEY = RubyUtil.RUBY.newSymbol("pipelines");

    public static final RubySymbol NAME_KEY = RubyUtil.RUBY.newSymbol("name");

    public static final RubySymbol EVENTS_KEY = RubyUtil.RUBY.newSymbol("events");

    public static final RubySymbol OUT_KEY = RubyUtil.RUBY.newSymbol("out");

    public static final RubySymbol IN_KEY = RubyUtil.RUBY.newSymbol("in");

    public static final RubySymbol DURATION_IN_MILLIS_KEY =
        RubyUtil.RUBY.newSymbol("duration_in_millis");

    public static final RubySymbol FILTERED_KEY = RubyUtil.RUBY.newSymbol("filtered");
}
