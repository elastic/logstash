package org.logstash.plugin;

import org.jruby.RubyArray;
import org.jruby.RubyObject;
import org.logstash.Event;
import org.logstash.ext.JrubyEventExtLibrary;

public class RubyOutput implements Output {
    private static final String MULTI_RECEIVE_METHOD = "multi_receive";
    private static final String RECEIVE_METHOD = "receive";
    private RubyObject plugin;
    private RubyArray events;
    private Output handler;

    public RubyOutput(RubyObject plugin) {
        // XXX: assert that `plugin` is a subclass of LogStash::Filter::Base
        this.plugin = plugin;
        events = RubyArray.newArray(plugin.getRuntime());

        // XXX: This could probably be split into 3 classes: A ProcessorFactory which produces a
        //      RubyMultiOutput and RubySingleOutput
        if (plugin.respondsTo("multi_receive")) {
            handler = this::processBatch;
        } else {
            handler = this::processIndividual;
        }
    }

    @Override
    public void process(Batch batch) {
        handler.process(batch);
    }

    private void processBatch(Batch batch) {
        events.clear();
        for (Event event : batch) {
            events.add(JrubyEventExtLibrary.RubyEvent.newRubyEvent(plugin.getRuntime(), event));
        }

        plugin.callMethod("multi_receive", events);
    }

    private void processIndividual(Batch batch) {
        for (Event event : batch) {
            plugin.callMethod("receive", JrubyEventExtLibrary.RubyEvent.newRubyEvent(plugin.getRuntime(), event));
        }
    }
}
