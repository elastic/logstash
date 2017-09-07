package org.logstash.plugin;

import org.jruby.RubyArray;
import org.jruby.RubyObject;
import org.logstash.Event;
import org.logstash.ext.JrubyEventExtLibrary;

public class RubyProcessor implements Processor {
    private static final String MULTI_FILTER_METHOD = "multi_filter";
    private static final String FILTER_METHOD = "filter";
    private RubyObject plugin;
    private RubyArray events;
    private Processor handler;

    public RubyProcessor(RubyObject plugin) {
        // XXX: assert that `filter` is a subclass of LogStash::Filter::Base
        this.plugin = plugin;
        events = RubyArray.newArray(plugin.getRuntime());

        // XXX: This could probably be split into 3 classes: A ProcessorFactory which produces a
        //      RubyMultiOutput and RubySingleOutput
        if (plugin.respondsTo(MULTI_FILTER_METHOD)) {
            handler = this::processBatch;
        } else {
            handler = this::processIndividual;
        }
    }

    @Override
    public void process(ProcessorBatch batch) {
        handler.process(batch);
    }

    private void processBatch(ProcessorBatch batch) {
        events.clear();
        for (Event event : batch) {
            events.add(JrubyEventExtLibrary.RubyEvent.newRubyEvent(plugin.getRuntime(), event));
        }

        plugin.callMethod(MULTI_FILTER_METHOD, events);

        for (Event event : batch) {
            if (event.isCancelled()) {
                batch.remove(event);
            }
        }
    }

    private void processIndividual(ProcessorBatch batch) {
        for (Event event : batch) {
            plugin.callMethod(FILTER_METHOD, JrubyEventExtLibrary.RubyEvent.newRubyEvent(plugin.getRuntime(), event));
            if (event.isCancelled()) {
                batch.remove(event);
            }
        }
    }
}
