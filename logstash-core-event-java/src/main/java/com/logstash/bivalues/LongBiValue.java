package com.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.RubyInteger;
import org.jruby.javasupport.JavaUtil;

public class LongBiValue extends BiValueCommon<RubyInteger, Long> implements BiValue<RubyInteger, Long> {

    public LongBiValue(RubyInteger rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public LongBiValue(long javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    private LongBiValue() {
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = (RubyInteger) JavaUtil.convertJavaToUsableRubyObject(runtime, javaValue);
    }

    protected void addJava() {
        javaValue = rubyValue.getLongValue();
    }
}
