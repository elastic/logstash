package com.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.RubyFloat;


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
}
