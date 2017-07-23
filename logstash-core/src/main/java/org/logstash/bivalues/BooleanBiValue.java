package org.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.RubyBoolean;

public final class BooleanBiValue extends BiValueCommon<RubyBoolean, Boolean> 
    implements BiValue<RubyBoolean, Boolean> {

    private static final long serialVersionUID = 126658646136243974L;

    public BooleanBiValue(RubyBoolean rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public BooleanBiValue(Boolean javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = RubyBoolean.newBoolean(runtime, javaValue);
    }

    protected void addJava() {
        javaValue = rubyValue.isTrue();
    }
}
