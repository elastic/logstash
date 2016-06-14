package com.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.ext.bigdecimal.RubyBigDecimal;

import java.math.BigDecimal;

public class BigDecimalBiValue extends BiValueCommon<RubyBigDecimal, BigDecimal> implements BiValue<RubyBigDecimal, BigDecimal> {

    public BigDecimalBiValue(RubyBigDecimal rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public BigDecimalBiValue(BigDecimal javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    private BigDecimalBiValue() {
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = new RubyBigDecimal(runtime, runtime.getClass("BigDecimal"), javaValue);
    }

    protected void addJava() {
        javaValue = rubyValue.getBigDecimalValue();
    }
}
