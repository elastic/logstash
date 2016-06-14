package com.logstash.bivalues;

import com.logstash.Timestamp;
import com.logstash.ext.JrubyTimestampExtLibrary.RubyTimestamp;
import org.jruby.Ruby;

public class TimestampBiValue extends BiValueCommon<RubyTimestamp, Timestamp> implements BiValue<RubyTimestamp, Timestamp> {

    public TimestampBiValue(RubyTimestamp rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public TimestampBiValue(Timestamp javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    private TimestampBiValue() {
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = RubyTimestamp.newRubyTimestamp(runtime, (Timestamp) javaValue);
    }

    protected void addJava() {
        javaValue = rubyValue.getTimestamp();
    }
}
