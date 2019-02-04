package org.logstash.plugins;

import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.Event;
import co.elastic.logstash.api.EventFactory;
import co.elastic.logstash.api.Plugin;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.ConvertedMap;
import org.logstash.common.io.DeadLetterQueueWriter;

import java.io.Serializable;
import java.util.Map;

public class ContextImpl implements Context {

    private DeadLetterQueueWriter dlqWriter;

    public ContextImpl(DeadLetterQueueWriter dlqWriter) {
        this.dlqWriter = dlqWriter;
    }

    @Override
    public DeadLetterQueueWriter getDlqWriter() {
        return dlqWriter;
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
