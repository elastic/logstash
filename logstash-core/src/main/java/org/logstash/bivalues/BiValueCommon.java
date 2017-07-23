package org.logstash.bivalues;

import com.fasterxml.jackson.annotation.JsonValue;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import org.jruby.Ruby;
import org.jruby.runtime.builtin.IRubyObject;

public abstract class BiValueCommon<R extends IRubyObject, J> implements Serializable {

    private static final long serialVersionUID = -5550024069165773235L;

    protected transient R rubyValue;
    protected transient J javaValue;

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

        if (hasJavaValue() && javaValue.getClass().isAssignableFrom(o.getClass())){
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
        if (hasRubyValue()) {
            javaValue();
        }
        if (javaValue == null) {
            return "";
        }
        return String.valueOf(javaValue);
    }

    private void writeObject(final ObjectOutputStream out) throws IOException {
        out.writeObject(this.javaValue());
    }

    private void readObject(final ObjectInputStream in) throws IOException, ClassNotFoundException {
        this.javaValue = (J) in.readObject();
    }
}
