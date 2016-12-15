package org.logstash.bivalues;

import org.joda.time.DateTime;
import org.jruby.Ruby;
import org.jruby.RubyTime;

import java.io.ObjectStreamException;


public class TimeBiValue extends BiValueCommon<RubyTime, DateTime> implements BiValue<RubyTime, DateTime> {

    public TimeBiValue(RubyTime rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public TimeBiValue(DateTime javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    private TimeBiValue() {
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = RubyTime.newTime(runtime, javaValue);
    }

    protected void addJava() {
        javaValue = rubyValue.getDateTime();
    }

    // Called when object is to be serialized on a stream to allow the object to substitute a proxy for itself.
    private Object writeReplace() throws ObjectStreamException {
        return newProxy(this);
    }
}
