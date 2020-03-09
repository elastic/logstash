package org.logstash.config.ir.compiler;

import co.elastic.logstash.api.Codec;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.common.SourceWithMetadata;

import java.util.Map;

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

        IRubyObject buildInput(RubyString name, SourceWithMetadata source,
                               IRubyObject args, Map<String, Object> pluginArgs);

        AbstractOutputDelegatorExt buildOutput(RubyString name, SourceWithMetadata source,
                                               IRubyObject args, Map<String, Object> pluginArgs);

        AbstractFilterDelegatorExt buildFilter(RubyString name, SourceWithMetadata source, IRubyObject args,
                                               Map<String, Object> pluginArgs);

        IRubyObject buildCodec(RubyString name, SourceWithMetadata source, IRubyObject args,
                               Map<String, Object> pluginArgs);

        Codec buildDefaultCodec(String codecName);

    }
}
