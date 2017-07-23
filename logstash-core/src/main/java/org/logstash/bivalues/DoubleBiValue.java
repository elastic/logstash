package org.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.RubyFloat;

public final class DoubleBiValue extends BiValueCommon<RubyFloat, Double> 
    implements BiValue<RubyFloat, Double> {

    private static final long serialVersionUID = 3434273761801429821L;

    public DoubleBiValue(RubyFloat rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public DoubleBiValue(Double javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = RubyFloat.newFloat(runtime, javaValue);
    }

    protected void addJava() {
        javaValue = rubyValue.getDoubleValue();
    }
}
