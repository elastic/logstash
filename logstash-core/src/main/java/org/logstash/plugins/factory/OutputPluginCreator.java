package org.logstash.plugins.factory;

import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.Output;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.config.ir.compiler.JavaOutputDelegatorExt;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.plugins.PluginLookup;

import java.util.Map;

class OutputPluginCreator extends AbstractPluginCreator<Output> {

    OutputPluginCreator(PluginFactoryExt pluginsFactory) {
        this.pluginsFactory = pluginsFactory;
    }

    @Override
    public IRubyObject createDelegator(String name, Map<String, Object> pluginArgs, String id,
                                       AbstractNamespacedMetricExt typeScopedMetric,
                                       PluginLookup.PluginClass pluginClass, Context pluginContext) {
        Output output = instantiateAndValidate(pluginArgs, id, pluginContext, pluginClass);
        return JavaOutputDelegatorExt.create(name, id, typeScopedMetric, output);
    }
}
