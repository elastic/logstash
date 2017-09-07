package org.logstash.plugin;

import org.jruby.RubyArray;
import org.jruby.RubyObject;
import org.logstash.Event;
import org.logstash.ext.JrubyEventExtLibrary;

public class RubyProcessor implements Processor {
    private static final String MULTI_FILTER_METHOD = "multi_filter";
    private RubyObject plugin;
    private RubyArray events;
    private Processor handler;

    public RubyProcessor(RubyObject plugin) {
        this.plugin = plugin;
        events = RubyArray.newArray(plugin.getRuntime());
    }

    @Override
    public void process(ProcessorBatch batch) {
        events.clear();
        for (Event event : batch) {
            events.add(JrubyEventExtLibrary.RubyEvent.newRubyEvent(plugin.getRuntime(), event));
        }

        // filters/base.rb provides a basic multi_filter even if the actual plugin itself does not.
        plugin.callMethod(MULTI_FILTER_METHOD, events);

        for (Event event : batch) {
            if (event.isCancelled()) {
                batch.remove(event);
            }
        }
    }
}
