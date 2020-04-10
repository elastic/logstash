package org.logstash.plugins.factory;

import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.Filter;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.config.ir.compiler.JavaFilterDelegatorExt;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.plugins.PluginLookup;

import java.util.Map;

class FilterPluginCreator extends AbstractPluginCreator<Filter> {

    @Override
    public IRubyObject createDelegator(String name, Map<String, Object> pluginArgs, String id,
                                       AbstractNamespacedMetricExt typeScopedMetric,
                                       PluginLookup.PluginClass pluginClass, Context pluginContext) {
        Filter filter = instantiateAndValidate(pluginArgs, id, pluginContext, pluginClass);
        return JavaFilterDelegatorExt.create(name, id, typeScopedMetric, filter, pluginArgs);
    }
}
