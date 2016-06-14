package com.logstash.bivalues;

import com.fasterxml.jackson.annotation.JsonValue;
import org.jruby.Ruby;
import org.jruby.RubyNil;

public class NullBiValue extends BiValueCommon<RubyNil, Object> implements BiValue<RubyNil, Object> {
    public static NullBiValue newNullBiValue() {
        return new NullBiValue();
    }

    public NullBiValue(RubyNil rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    private NullBiValue() {
        rubyValue = null;
        javaValue = null;
    }

    @JsonValue
    @Override
    public Object javaValue() {
        return null;
    }

    @Override
    public boolean hasJavaValue() {
        return true;
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = (RubyNil) runtime.getNil();
    }

    protected void addJava() {}
}
