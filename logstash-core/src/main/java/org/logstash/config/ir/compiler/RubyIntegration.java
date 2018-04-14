package org.logstash.config.ir.compiler;

import org.jruby.RubyInteger;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * This class holds interfaces implemented by Ruby concrete classes.
 */
public final class RubyIntegration {

    private RubyIntegration() {
        //Utility Class.
    }

    /**
     * Plugin Factory that instantiates Ruby plugins and is implemented in Ruby.
     */
    public interface PluginFactory {

        IRubyObject buildInput(RubyString name, RubyInteger line, RubyInteger column,
            IRubyObject args);

        OutputDelegatorExt buildOutput(RubyString name, RubyInteger line, RubyInteger column,
            IRubyObject args);

        FilterDelegatorExt buildFilter(RubyString name, RubyInteger line, RubyInteger column,
            IRubyObject args);

        IRubyObject buildCodec(RubyString name, IRubyObject args);
    }
}
