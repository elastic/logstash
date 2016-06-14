package com.logstash.bivalues;

import com.fasterxml.jackson.annotation.JsonValue;
import org.jruby.Ruby;
import org.jruby.runtime.builtin.IRubyObject;

public abstract class BiValueCommon<R extends IRubyObject, J> {
    protected transient R rubyValue;
    protected J javaValue;

    public R rubyValue(Ruby runtime) {
        if (hasRubyValue()) {
            return rubyValue;
        }
        addRuby(runtime);
        return rubyValue;
    }

    @JsonValue
    public J javaValue() {
        if (javaValue == null) {
            addJava();
        }
        return javaValue;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;

        if (javaValue.getClass().isAssignableFrom(o.getClass())){
            return javaValue.equals(o);
        }

        if(!(o instanceof BiValue)) {
            return false;
        }

        BiValueCommon<?, ?> other = (BiValueCommon<?, ?>) o;

        return (other.hasJavaValue() && other.javaValue().equals(javaValue)) ||
                (other.hasRubyValue() && other.rubyValueUnconverted().equals(rubyValue));

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

    public R rubyValueUnconverted() {
        return rubyValue;
    }

    public boolean hasRubyValue() {
        return null != rubyValue;
    }

    public boolean hasJavaValue() {
        return null != javaValue;
    }

    protected abstract void addRuby(Ruby runtime);

    protected abstract void addJava();

    @Override
    public String toString() {
        final StringBuffer sb = new StringBuffer(this.getClass().getSimpleName());
        sb.append("{rubyValue=").append(rubyValue);
        sb.append(", javaValue=").append(javaValue);
        sb.append('}');
        return sb.toString();
    }
}
