package org.logstash.plugins;

import co.elastic.logstash.api.*;
import org.apache.logging.log4j.Logger;

public class TestContext implements Context {

    @Override
    public DeadLetterQueueWriter getDlqWriter() {
        return null;
    }

    @Override
    public NamespacedMetric getMetric(final Plugin plugin) {
        return null;
    }

    @Override
    public Logger getLogger(Plugin plugin) {
        return null;
    }

    @Override
    public DeprecationLogger getDeprecationLogger(Plugin plugin) {
        return null;
    }

    @Override
    public EventFactory getEventFactory() { return null; }

}