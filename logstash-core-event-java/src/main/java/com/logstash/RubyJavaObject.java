package com.logstash;

import com.fasterxml.jackson.annotation.JsonValue;
import org.jruby.Ruby;
import org.jruby.RubyNil;
import org.jruby.runtime.builtin.IRubyObject;

import java.io.InvalidObjectException;
import java.io.ObjectStreamException;
import java.io.Serializable;
import java.io.ObjectInputStream;

public final class RubyJavaObject implements Serializable {
    private static final long serialVersionUID = 4358368393114318978L;

    private transient IRubyObject rubyValue;
    private transient boolean isRubyNil;
    private Object javaValue;

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
        if (hasRubyValue() && isRubyNil) {
            return null;
        }
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
    public String toString() {
        final StringBuilder sb = new StringBuilder("RubyJavaObject{");
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

    private static class SerializationProxy implements Serializable {
        private final Object javaValue;

        public SerializationProxy(RubyJavaObject o) {
            // ensure the javaValue is converted from a ruby one if it exists
            this.javaValue = o.getJavaValue();
        }

        /**
         * Called when object has been deserialized from a stream.
         *
         * @return {@code this}, or a replacement for {@code this}.
         * @throws ObjectStreamException if the object cannot be restored.
         * @see <a href="http://download.oracle.com/javase/1.3/docs/guide/serialization/spec/input.doc6.html">The Java Object Serialization Specification</a>
         */
        private Object readResolve() throws ObjectStreamException {
            return new RubyJavaObject(javaValue);
        }
    }

    /**
     * Called when object is to be serialized on a stream to allow the object to substitute a proxy for itself.
     *
     * @return {@code this}, or the proxy for {@code this}.
     * @throws ObjectStreamException if the object cannot be proxied.
     * @see <a href="http://download.oracle.com/javase/1.3/docs/guide/serialization/spec/output.doc5.html">The Java Object Serialization Specification</a>
     */
    private Object writeReplace() throws ObjectStreamException {
        return new SerializationProxy(this);
    }

    private void readObject(ObjectInputStream stream)
            throws InvalidObjectException {
        throw new InvalidObjectException("Proxy required");
    }
}
