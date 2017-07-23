package org.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.RubyFloat;

public final class FloatBiValue extends BiValueCommon<RubyFloat, Float> 
    implements BiValue<RubyFloat, Float> {

    private static final long serialVersionUID = 3076337527056049715L;

    public FloatBiValue(RubyFloat rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public FloatBiValue(Float javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
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
}
