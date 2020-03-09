package org.logstash.plugins.outputs;

import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.Event;
import co.elastic.logstash.api.LogstashPlugin;
import co.elastic.logstash.api.Output;
import co.elastic.logstash.api.PluginConfigSpec;
import co.elastic.logstash.api.PluginHelper;

import java.util.Collection;

@LogstashPlugin(name = "sink")
public class Sink implements Output {


    private final String id;

    public Sink(final String id, final Configuration configuration, final Context context) {
        this.id = id;
    }

    @Override
    public void output(Collection<Event> events) {

    }

    @Override
    public void stop() {

    }

    @Override
    public void awaitStop() throws InterruptedException {

    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        return PluginHelper.commonOutputSettings();
    }

    @Override
    public String getId() {
        return id;
    }
}
