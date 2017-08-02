package org.logstash.bivalues;

import com.fasterxml.jackson.annotation.JsonValue;
import org.jruby.Ruby;
import org.jruby.RubyString;

public final class StringBiValue extends BiValueCommon<RubyString, String>
    implements BiValue<RubyString, String> {

    private static final long serialVersionUID = -1059663228107569565L;

    public StringBiValue(RubyString rubyValue) {
        this.rubyValue = rubyValue;
    }

    public StringBiValue(String javaValue) {
        this.javaValue = javaValue;
        rubyValue = null;
    }

    @Override
    @JsonValue
    public String javaValue() {
        return rubyValue != null ? rubyValue.toString() : javaValue;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o instanceof BiValue) {
            final BiValueCommon<?, ?> other = (BiValueCommon<?, ?>) o;
            return other.hasRubyValue() && other.rubyValueUnconverted().equals(rubyValue) ||
                (other.hasJavaValue() && other.javaValue().equals(this.javaValue()));
        } else {
            return String.class.isAssignableFrom(o.getClass()) && this.javaValue().equals(o);
        }
    }

    protected void addRuby(Ruby runtime) {
        rubyValue = RubyString.newUnicodeString(runtime, javaValue);
    }

    @Override
    protected void addJava() {
    }

    @Override
    public boolean hasJavaValue() {
        return true;
    }
}
