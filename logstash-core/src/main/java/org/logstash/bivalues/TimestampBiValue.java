package org.logstash.bivalues;

import org.jruby.Ruby;
import org.logstash.Timestamp;
import org.logstash.ext.JrubyTimestampExtLibrary.RubyTimestamp;

public final class TimestampBiValue extends BiValueCommon<RubyTimestamp, Timestamp> 
    implements BiValue<RubyTimestamp, Timestamp> {

    private static final long serialVersionUID = -4868460704798452962L;

    public TimestampBiValue(RubyTimestamp rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public TimestampBiValue(Timestamp javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = RubyTimestamp.newRubyTimestamp(runtime, javaValue);
    }

    protected void addJava() {
        javaValue = rubyValue.getTimestamp();
    }
}
