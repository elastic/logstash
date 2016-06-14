package com.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.RubyString;

public class StringBiValue extends BiValueCommon<RubyString, String> implements BiValue<RubyString, String> {

    public StringBiValue(RubyString rubyValue) {
        this.rubyValue = rubyValue;
        javaValue = null;
    }

    public StringBiValue(String javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    private StringBiValue() {
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = RubyString.newUnicodeString(runtime, javaValue);
    }

    protected void addJava() {
        javaValue = rubyValue.asJavaString();
    }
}
