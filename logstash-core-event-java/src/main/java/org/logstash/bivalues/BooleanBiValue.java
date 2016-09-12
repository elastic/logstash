package org.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.RubyBoolean;

import java.io.ObjectStreamException;


public class BooleanBiValue extends BiValueCommon<RubyBoolean, Boolean> implements BiValue<RubyBoolean, Boolean> {

    public BooleanBiValue(RubyBoolean rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public BooleanBiValue(Boolean javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    private BooleanBiValue() {
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = RubyBoolean.newBoolean(runtime, javaValue);
    }

    protected void addJava() {
        javaValue = rubyValue.isTrue();
    }

    // Called when object is to be serialized on a stream to allow the object to substitute a proxy for itself.
    private Object writeReplace() throws ObjectStreamException {
        return newProxy(this);
    }
}
