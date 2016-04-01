package com.logstash;

import com.fasterxml.jackson.annotation.JsonValue;
import org.jruby.Ruby;
import org.jruby.runtime.builtin.IRubyObject;

import java.io.Serializable;

public class RubyJavaObject implements Serializable {
    private IRubyObject rubyValue;
    private Object javaValue;

    public RubyJavaObject(Object javaValue) {
        this.javaValue = javaValue;
        this.rubyValue = null;
    }

    public RubyJavaObject(IRubyObject rubyValue) {
        this.rubyValue = rubyValue;
        this.javaValue = null;
    }

    public IRubyObject getRubyValue(Ruby runtime) {
        if (rubyValue == null) {
            rubyValue = Rubyfier.deep(runtime, javaValue);
        }
        return rubyValue;
    }

    @JsonValue
    public Object getJavaValue() {
        if (javaValue == null) {
            javaValue = Javafier.deep(rubyValue);
        }
        return javaValue;
    }

    public Object javaGetRubyValue() {
        return rubyValue;
    }

    public boolean hasRubyValue() {
        return null != rubyValue;
    }

    public boolean hasJavaValue() {
        return null != javaValue;
    }

    @Override
    public boolean equals(Object o) {
        if (!(o instanceof RubyJavaObject)) return false;
        RubyJavaObject other = (RubyJavaObject) o;
        return (other.hasJavaValue() && other.getJavaValue().equals(javaValue)) ||
                (other.hasRubyValue() && other.javaGetRubyValue().equals(rubyValue));
    }

    @Override
    public int hashCode() {
        if (hasRubyValue()) {
            return rubyValue.hashCode();
        }
        if (hasJavaValue()) {
            return javaValue.hashCode();
        }
        return 0;
    }
}
