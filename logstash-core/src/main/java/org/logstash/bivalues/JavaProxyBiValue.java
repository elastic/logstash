package org.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.java.proxies.JavaProxy;
import org.jruby.javasupport.JavaUtil;

import java.io.ObjectStreamException;

public class JavaProxyBiValue extends BiValueCommon<JavaProxy, Object> implements BiValue<JavaProxy, Object> {

    public JavaProxyBiValue(JavaProxy rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public JavaProxyBiValue(Object javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    private JavaProxyBiValue() {
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = (JavaProxy) JavaUtil.convertJavaToUsableRubyObject(runtime, javaValue);
    }

    protected void addJava() {
        javaValue = rubyValue.getObject();
    }

    // Called when object is to be serialized on a stream to allow the object to substitute a proxy for itself.
    private Object writeReplace() throws ObjectStreamException {
        return newProxy(this);
    }
}
