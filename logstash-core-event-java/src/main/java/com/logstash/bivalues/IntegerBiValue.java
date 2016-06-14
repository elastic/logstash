package com.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.RubyInteger;
import org.jruby.javasupport.JavaUtil;

public class IntegerBiValue extends BiValueCommon<RubyInteger, Integer> implements BiValue<RubyInteger, Integer> {

    public IntegerBiValue(RubyInteger rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public IntegerBiValue(int javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    private IntegerBiValue() {
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = (RubyInteger) JavaUtil.convertJavaToUsableRubyObject(runtime, javaValue);
    }

    protected void addJava() {
        long value = rubyValue.getLongValue();
        if ((int) value != value) {
            throw new ArithmeticException("Integer overflow - Incorrect IntegerBiValue usage: BiValues should pick LongBiValue for RubyInteger");
        }
        javaValue = (int) value;
    }
}
