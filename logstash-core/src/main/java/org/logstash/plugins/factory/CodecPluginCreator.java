package org.logstash.plugins.factory;

import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Context;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.config.ir.compiler.JavaCodecDelegator;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.plugins.PluginLookup;

import java.util.Map;

class CodecPluginCreator extends AbstractPluginCreator<Codec> {

    @Override
    public IRubyObject createDelegator(String name, Map<String, Object> pluginArgs, String id,
                                       AbstractNamespacedMetricExt typeScopedMetric,
                                       PluginLookup.PluginClass pluginClass, Context pluginContext) {
        Codec codec = instantiateAndValidate(pluginArgs, id, pluginContext, pluginClass);
        return JavaUtil.convertJavaToRuby(RubyUtil.RUBY, new JavaCodecDelegator(pluginContext, codec));
    }
}
