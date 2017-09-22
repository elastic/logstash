package org.logstash.plugin;

import org.jruby.RubyArray;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.Event;
import org.logstash.ext.JrubyEventExtLibrary.RubyEvent;

import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

public class RubyProcessor implements Processor {
    private static final Collection<Event> EMPTY_RESULT = Collections.emptyList();

    private static final String MULTI_FILTER_METHOD = "multi_filter";
    private IRubyObject plugin;
    private Processor handler;

    public RubyProcessor(IRubyObject plugin) {
        this.plugin = plugin;
    }

    @Override
    public Collection<Event> process(Collection<Event> events) {
        final RubyArray rubyEvents = RubyArray.newArray(plugin.getRuntime());
        events.forEach(event -> rubyEvents.add(RubyEvent.newRubyEvent(plugin.getRuntime(), event)));

        // filters/base.rb provides a basic multi_filter even if the actual plugin itself does not.
        IRubyObject result = plugin.callMethod(plugin.getRuntime().getCurrentContext(), MULTI_FILTER_METHOD, rubyEvents);

        if (result.isNil()) {
            return EMPTY_RESULT;
        }

        // `result` must be a RubyArray containing RubyEvent's
        if (result instanceof RubyArray) {
            @SuppressWarnings("unchecked") // RubyArray is not generic, but satisfies `List`.
            final List<RubyEvent> newRubyEvents = (RubyArray) result;
            return newRubyEvents.stream().map(RubyEvent::getEvent).collect(Collectors.toList());
        } else {
            throw new IllegalArgumentException("Return value from a filter must be nil or an array of events, but got " + result.getClass().getCanonicalName());
        }
    }
}
