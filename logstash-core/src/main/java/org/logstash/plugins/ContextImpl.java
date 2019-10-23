package org.logstash.plugins;

import co.elastic.logstash.api.*;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.ConvertedMap;
import org.logstash.log.DefaultDeprecationLogger;

import java.io.Serializable;
import java.util.Map;

public class ContextImpl implements Context {

    private DeadLetterQueueWriter dlqWriter;

    /**
     * This is a reference to the [stats, pipelines, *name*, plugins] metric namespace.
     */
    private Metric pluginsScopedMetric;

    public ContextImpl(DeadLetterQueueWriter dlqWriter, Metric metric) {
        this.dlqWriter = dlqWriter;
        this.pluginsScopedMetric = metric;
    }

    @Override
    public DeadLetterQueueWriter getDlqWriter() {
        return dlqWriter;
    }

    @Override
    public NamespacedMetric getMetric(Plugin plugin) {
        return pluginsScopedMetric.namespace(PluginLookup.PluginType.getTypeByPlugin(plugin).metricNamespace(), plugin.getId());
    }

    @Override
    public Logger getLogger(Plugin plugin) {
        return LogManager.getLogger(plugin.getClass());
    }

    @Override
    public DeprecationLogger getDeprecationLogger(Plugin plugin) {
        return new DefaultDeprecationLogger(getLogger(plugin));
    }

    @Override
    public EventFactory getEventFactory() {
        return new EventFactory() {
            @Override
            public Event newEvent() {
                return new org.logstash.Event();
            }

            @Override
            public Event newEvent(Map<? extends Serializable, Object> data) {
                if (data instanceof ConvertedMap) {
                    return new org.logstash.Event((ConvertedMap)data);
                }
                return new org.logstash.Event(data);
            }
        };
    }
}
