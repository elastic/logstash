package org.logstash.plugins.factory;

import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.Input;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.config.ir.compiler.JavaInputDelegatorExt;
import org.logstash.execution.AbstractPipelineExt;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.plugins.PluginLookup;

import java.util.Map;

class InputPluginCreator extends AbstractPluginCreator<Input> {

    InputPluginCreator(PluginFactoryExt pluginsFactory) {
        this.pluginsFactory = pluginsFactory;
    }

    @Override
    public IRubyObject createDelegator(String name, Map<String, Object> pluginArgs, String id,
                                       AbstractNamespacedMetricExt typeScopedMetric,
                                       PluginLookup.PluginClass pluginClass, Context pluginContext) {
        Input input = instantiateAndValidate(pluginArgs, id, pluginContext, pluginClass);
        return JavaInputDelegatorExt.create((AbstractPipelineExt) pluginsFactory.getExecutionContextFactory().getPipeline(),
                typeScopedMetric, input, pluginArgs);
    }
}
