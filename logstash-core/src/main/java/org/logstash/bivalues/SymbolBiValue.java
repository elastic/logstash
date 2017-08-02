package org.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.RubySymbol;

public final class SymbolBiValue extends BiValueCommon<RubySymbol, String> 
    implements BiValue<RubySymbol, String> {

    private static final long serialVersionUID = -2010627976505908822L;

    public SymbolBiValue(RubySymbol rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public SymbolBiValue(String javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = RubySymbol.newSymbol(runtime, javaValue);
    }

    protected void addJava() {
        javaValue = rubyValue.asJavaString();
    }
}
