package org.logstash.plugins;

import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.Event;
import co.elastic.logstash.api.EventFactory;
import co.elastic.logstash.api.Metric;
import co.elastic.logstash.api.NamespacedMetric;
import co.elastic.logstash.api.Plugin;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.ConvertedMap;
import org.logstash.common.io.DeadLetterQueueWriter;

import java.io.Serializable;
import java.util.Map;

public class ContextImpl implements Context {

    private DeadLetterQueueWriter dlqWriter;

    private Metric metric;

    public ContextImpl(DeadLetterQueueWriter dlqWriter, Metric metric) {
        this.dlqWriter = dlqWriter;
        this.metric = metric;
    }

    @Override
    public DeadLetterQueueWriter getDlqWriter() {
        return dlqWriter;
    }

    @Override
    public NamespacedMetric getMetric(Plugin plugin) {
        return metric.namespace(PluginLookup.PluginType.getTypeByPlugin(plugin).label(), plugin.getId());
    }

    @Override
    public Logger getLogger(Plugin plugin) {
        return LogManager.getLogger(plugin.getClass());
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
