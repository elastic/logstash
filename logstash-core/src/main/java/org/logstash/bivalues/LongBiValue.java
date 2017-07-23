package org.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.RubyInteger;
import org.jruby.javasupport.JavaUtil;

public final class LongBiValue extends BiValueCommon<RubyInteger, Long>
    implements BiValue<RubyInteger, Long> {

    private static final long serialVersionUID = -6119062523375669671L;

    public LongBiValue(RubyInteger rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public LongBiValue(long javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = (RubyInteger) JavaUtil.convertJavaToUsableRubyObject(runtime, javaValue);
    }

    protected void addJava() {
        javaValue = rubyValue.getLongValue();
    }
}
