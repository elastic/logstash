package org.logstash.plugins.factory;

import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.Plugin;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.plugins.ConfigurationImpl;
import org.logstash.plugins.PluginLookup;
import org.logstash.plugins.PluginUtil;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.util.Map;

abstract class AbstractPluginCreator<T extends Plugin> {

    protected PluginFactoryExt pluginsFactory = null;

    abstract IRubyObject createDelegator(String name, Map<String, Object> pluginArgs, String id,
                                AbstractNamespacedMetricExt typeScopedMetric,
                                PluginLookup.PluginClass pluginClass, Context pluginContext);

    protected T instantiateAndValidate(Map<String, Object> pluginArgs, String id, Context pluginContext,
                                       PluginLookup.PluginClass pluginClass) {
        @SuppressWarnings("unchecked")
        final Class<T> cls = (Class<T>) pluginClass.klass();
        if (cls == null) {
            throw new IllegalStateException("Unable to instantiate type: " + pluginClass);
        }

        try {
            final Constructor<T> ctor = cls.getConstructor(String.class, Configuration.class, Context.class);
            Configuration config = new ConfigurationImpl(pluginArgs, pluginsFactory);
            T plugin = ctor.newInstance(id, config, pluginContext);
            PluginUtil.validateConfig(plugin, config);
            return plugin;
        } catch (NoSuchMethodException | IllegalAccessException | InstantiationException | InvocationTargetException ex) {
            if (ex instanceof InvocationTargetException && ex.getCause() != null) {
                throw new IllegalStateException((ex).getCause());
            }
            throw new IllegalStateException(ex);
        }
    }
}
