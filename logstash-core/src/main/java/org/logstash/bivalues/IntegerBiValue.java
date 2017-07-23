package org.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.RubyInteger;
import org.jruby.javasupport.JavaUtil;

public final class IntegerBiValue extends BiValueCommon<RubyInteger, Integer> 
    implements BiValue<RubyInteger, Integer> {

    private static final long serialVersionUID = -3220011682769931400L;

    public IntegerBiValue(RubyInteger rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public IntegerBiValue(int javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
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
