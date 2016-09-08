package org.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.RubyFloat;

import java.io.ObjectStreamException;


public class DoubleBiValue extends BiValueCommon<RubyFloat, Double> implements BiValue<RubyFloat, Double> {

    public DoubleBiValue(RubyFloat rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public DoubleBiValue(Double javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    private DoubleBiValue() {
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = RubyFloat.newFloat(runtime, javaValue);
    }

    protected void addJava() {
        javaValue = rubyValue.getDoubleValue();
    }

    // Called when object is to be serialized on a stream to allow the object to substitute a proxy for itself.
    private Object writeReplace() throws ObjectStreamException {
        return newProxy(this);
    }
}
