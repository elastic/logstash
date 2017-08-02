package org.logstash.bivalues;

import org.joda.time.DateTime;
import org.jruby.Ruby;
import org.jruby.RubyTime;

public final class TimeBiValue extends BiValueCommon<RubyTime, DateTime> 
    implements BiValue<RubyTime, DateTime> {

    private static final long serialVersionUID = -8792359519343205099L;

    public TimeBiValue(RubyTime rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public TimeBiValue(DateTime javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = RubyTime.newTime(runtime, javaValue);
    }

    protected void addJava() {
        javaValue = rubyValue.getDateTime();
    }
}
