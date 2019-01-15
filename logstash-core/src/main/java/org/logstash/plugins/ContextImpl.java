package org.logstash.plugins;

import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.Plugin;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.common.io.DeadLetterQueueWriter;

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

}
