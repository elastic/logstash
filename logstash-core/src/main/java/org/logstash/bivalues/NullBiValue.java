package org.logstash.bivalues;

import com.fasterxml.jackson.annotation.JsonValue;
import org.jruby.Ruby;
import org.jruby.RubyNil;

public final class NullBiValue extends BiValueCommon<RubyNil, Object>
    implements BiValue<RubyNil, Object> {

    private static final NullBiValue INSTANCE =
        new NullBiValue((RubyNil) Ruby.getGlobalRuntime().getNil());

    private static final long serialVersionUID = 3324022424426763767L;

    public static NullBiValue newNullBiValue() {
        return INSTANCE;
    }

    private NullBiValue(final RubyNil rubyValue) {
        this.rubyValue = rubyValue;
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

    @Override
    public boolean hasRubyValue() {
        return true;
    }

    @Override
    protected void addRuby(Ruby runtime) {}

    @Override
    protected void addJava() {}
}
