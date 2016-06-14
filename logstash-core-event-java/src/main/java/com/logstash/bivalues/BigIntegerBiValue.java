package com.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.RubyBignum;

import java.math.BigInteger;

public class BigIntegerBiValue extends BiValueCommon<RubyBignum, BigInteger> implements BiValue<RubyBignum, BigInteger> {

    public BigIntegerBiValue(RubyBignum rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public BigIntegerBiValue(BigInteger javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    private BigIntegerBiValue() {
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = new RubyBignum(runtime, javaValue);
    }

    protected void addJava() {
        javaValue = rubyValue.getValue();
    }
}
