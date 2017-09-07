package org.logstash.plugin;

import org.jruby.RubyArray;
import org.jruby.RubyObject;
import org.logstash.Event;
import org.logstash.ext.JrubyEventExtLibrary;

import java.util.Collection;

public class RubyOutput implements Output {
    private static final String MULTI_RECEIVE_METHOD = "multi_receive";
    private RubyObject plugin;
    private RubyArray events;
    private Output handler;

    public RubyOutput(RubyObject plugin) {
        // XXX: assert that `plugin` is a subclass of LogStash::Filter::Base
        this.plugin = plugin;
        events = RubyArray.newArray(plugin.getRuntime());


    }
    @Override
    public void process(Collection<Event> events) {
        final RubyArray rubyEvents = RubyArray.newArray(plugin.getRuntime());
        events.forEach(event -> rubyEvents.add(JrubyEventExtLibrary.RubyEvent.newRubyEvent(plugin.getRuntime(), event)));
        plugin.callMethod(plugin.getRuntime().getCurrentContext(), MULTI_RECEIVE_METHOD, rubyEvents);
    }
}
