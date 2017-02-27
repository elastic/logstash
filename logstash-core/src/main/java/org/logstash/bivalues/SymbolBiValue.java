package org.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.RubySymbol;

import java.io.ObjectStreamException;

public class SymbolBiValue extends BiValueCommon<RubySymbol, String> implements BiValue<RubySymbol, String> {

    public SymbolBiValue(RubySymbol rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public SymbolBiValue(String javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    private SymbolBiValue() {
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = RubySymbol.newSymbol(runtime, javaValue);
    }

    protected void addJava() {
        javaValue = rubyValue.asJavaString();
    }

    // Called when object is to be serialized on a stream to allow the object to substitute a proxy for itself.
    private Object writeReplace() throws ObjectStreamException {
        return newProxy(this);
    }
}
