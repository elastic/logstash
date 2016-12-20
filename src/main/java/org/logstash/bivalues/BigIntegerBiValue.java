package org.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.RubyBignum;

import java.io.ObjectStreamException;
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

    // Called when object is to be serialized on a stream to allow the object to substitute a proxy for itself.
    private Object writeReplace() throws ObjectStreamException {
        return newProxy(this);
    }
}
