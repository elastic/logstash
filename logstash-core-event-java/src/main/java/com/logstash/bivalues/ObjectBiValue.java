package com.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;

import java.io.ObjectStreamException;

// Guy: I am not sure we need this class
// it was meant to be supplied as a fall-back when BiValues.newBiValue(obj) returns nothing.
// i.e. when JRuby wraps a value in a JavaProxy, however, we don't want Maps, Lists or arrays in a BiValue
// or when there is a JRuby class that has no java equivalent, for example, a custom class.
// in the case of a ConcreteProxy, toJava(Object.class) will return the wrapped Java object.
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

    // Called when object is to be serialized on a stream to allow the object to substitute a proxy for itself.
    private Object writeReplace() throws ObjectStreamException {
        return newProxy(this);
    }
}
