package com.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;

public class ObjectBiValue extends BiValueCommon<IRubyObject, Object> implements BiValue<IRubyObject, Object> {

    public ObjectBiValue(IRubyObject rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public ObjectBiValue(Object javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    private ObjectBiValue() {
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = JavaUtil.convertJavaToUsableRubyObject(runtime, javaValue);
    }

    protected void addJava() {
        javaValue = rubyValue.toJava(Object.class);
    }
}
