package org.logstash.plugins;

import co.elastic.logstash.api.Codec;
import org.jruby.RubyInteger;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.config.ir.compiler.AbstractFilterDelegatorExt;
import org.logstash.config.ir.compiler.AbstractOutputDelegatorExt;
import org.logstash.config.ir.compiler.RubyIntegration;
import org.logstash.plugins.codecs.Line;

import java.util.Collections;
import java.util.Map;

public class TestPluginFactory implements RubyIntegration.PluginFactory {

    @Override
    public IRubyObject buildInput(RubyString name, RubyInteger line, RubyInteger column, String sourceFile, int sourceLine, IRubyObject args, Map<String, Object> pluginArgs) {
        return null;
    }

    @Override
    public AbstractOutputDelegatorExt buildOutput(RubyString name, RubyInteger line, RubyInteger column, String sourceFile, int sourceLine, IRubyObject args, Map<String, Object> pluginArgs) {
        return null;
    }

    @Override
    public AbstractFilterDelegatorExt buildFilter(RubyString name, RubyInteger line, RubyInteger column, String sourceFile, int sourceLine, IRubyObject args, Map<String, Object> pluginArgs) {
        return null;
    }

    @Override
    public IRubyObject buildCodec(RubyString name, String sourceFile, int sourceLine, IRubyObject args, Map<String, Object> pluginArgs) {
        return null;
    }

    @Override
    public Codec buildDefaultCodec(String codecName) {
        return new Line(new ConfigurationImpl(Collections.emptyMap()), new ContextImpl(null, null));
    }
}
