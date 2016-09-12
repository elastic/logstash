package org.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.RubyFloat;

import java.io.ObjectStreamException;


public class FloatBiValue extends BiValueCommon<RubyFloat, Float> implements BiValue<RubyFloat, Float> {

    public FloatBiValue(RubyFloat rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public FloatBiValue(Float javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    private FloatBiValue() {
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = RubyFloat.newFloat(runtime, (double)javaValue);
    }

    protected void addJava() {
        double value = rubyValue.getDoubleValue();
        if ((float) value != value) {
            throw new ArithmeticException("Float overflow - Incorrect FloatBiValue usage: BiValues should pick DoubleBiValue for RubyFloat");
        }
        javaValue = (float) value;
    }

    // Called when object is to be serialized on a stream to allow the object to substitute a proxy for itself.
    private Object writeReplace() throws ObjectStreamException {
        return newProxy(this);
    }
}
