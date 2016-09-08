package org.logstash.bivalues;

import com.fasterxml.jackson.annotation.JsonValue;
import org.jruby.Ruby;
import org.jruby.RubyNil;

import java.io.ObjectStreamException;

public class NullBiValue extends BiValueCommon<RubyNil, Object> implements BiValue<RubyNil, Object> {
    public static NullBiValue newNullBiValue() {
        return new NullBiValue();
    }

    public NullBiValue(RubyNil rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    private NullBiValue() {
        rubyValue = null;
        javaValue = null;
    }

    @JsonValue
    @Override
    public Object javaValue() {
        return null;
    }

    @Override
    public boolean hasJavaValue() {
        return true;
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = (RubyNil) runtime.getNil();
    }

    protected void addJava() {}

    // Called when object is to be serialized on a stream to allow the object to substitute a proxy for itself.
    private Object writeReplace() throws ObjectStreamException {
        return newProxy(this);
    }
}
