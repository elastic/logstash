package com.logstash;

import com.fasterxml.jackson.annotation.JsonValue;
import org.jruby.Ruby;
import org.jruby.RubyNil;
import org.jruby.runtime.builtin.IRubyObject;

import java.io.Serializable;

public class RubyJavaObject implements Serializable {
    private IRubyObject rubyValue;
    private Object javaValue;
    private boolean isRubyNil;

    public RubyJavaObject(Object javaValue) {
        this.javaValue = javaValue;
        this.rubyValue = null;
    }

    public RubyJavaObject(IRubyObject rubyValue) {
        this.rubyValue = rubyValue;
        isRubyNil = (this.rubyValue instanceof RubyNil);
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
        if (isRubyNil) {
            return null;
        }
        if (javaValue == null) {
            javaValue = Javafier.deep(rubyValue);
        }
        return javaValue;
    }

    public void update(final RubyJavaObject other) {
        this.rubyValue = other.getRawRubyValue();
        this.javaValue = other.getRawJavaValue();
    }

    protected IRubyObject getRawRubyValue() {
        return rubyValue;
    }

    protected Object getRawJavaValue() {
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

    public boolean isRubyNil() {  return isRubyNil; }

    @Override
    public String toString() {
        final StringBuffer sb = new StringBuffer("RubyJavaObject{");
        sb.append("rubyValue=").append(isRubyNil ? "nil" : rubyValue);
        sb.append(", javaValue=").append(javaValue);
        sb.append('}');
        return sb.toString();
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
