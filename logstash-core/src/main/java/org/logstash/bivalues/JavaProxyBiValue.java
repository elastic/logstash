package org.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.java.proxies.JavaProxy;
import org.jruby.javasupport.JavaUtil;

public final class JavaProxyBiValue extends BiValueCommon<JavaProxy, Object> 
    implements BiValue<JavaProxy, Object> {

    private static final long serialVersionUID = 9127622347449815350L;

    public JavaProxyBiValue(JavaProxy rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public JavaProxyBiValue(Object javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = (JavaProxy) JavaUtil.convertJavaToUsableRubyObject(runtime, javaValue);
    }

    protected void addJava() {
        javaValue = rubyValue.getObject();
    }
}
