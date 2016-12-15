package org.logstash.bivalues;

import org.logstash.Timestamp;
import org.logstash.ext.JrubyTimestampExtLibrary.RubyTimestamp;
import org.jruby.Ruby;

import java.io.ObjectStreamException;

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

    // Called when object is to be serialized on a stream to allow the object to substitute a proxy for itself.
    private Object writeReplace() throws ObjectStreamException {
        return newProxy(this);
    }
}
