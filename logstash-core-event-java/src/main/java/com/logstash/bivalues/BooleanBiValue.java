package com.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.RubyBoolean;


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
}
