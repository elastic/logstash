package org.logstash.bivalues;

import java.math.BigDecimal;
import org.jruby.Ruby;
import org.jruby.ext.bigdecimal.RubyBigDecimal;

public final class BigDecimalBiValue extends BiValueCommon<RubyBigDecimal, BigDecimal> 
    implements BiValue<RubyBigDecimal, BigDecimal> {

    private static final long serialVersionUID = -3408830056779123333L;

    public BigDecimalBiValue(RubyBigDecimal rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public BigDecimalBiValue(BigDecimal javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = new RubyBigDecimal(runtime, runtime.getClass("BigDecimal"), javaValue);
    }

    protected void addJava() {
        javaValue = rubyValue.getBigDecimalValue();
    }
}
