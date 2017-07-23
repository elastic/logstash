package org.logstash.bivalues;

import java.math.BigInteger;
import org.jruby.Ruby;
import org.jruby.RubyBignum;

public final class BigIntegerBiValue extends BiValueCommon<RubyBignum, BigInteger> 
    implements BiValue<RubyBignum, BigInteger> {

    private static final long serialVersionUID = -6779003043647264917L;

    public BigIntegerBiValue(RubyBignum rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public BigIntegerBiValue(BigInteger javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = new RubyBignum(runtime, javaValue);
    }

    protected void addJava() {
        javaValue = rubyValue.getValue();
    }
}
