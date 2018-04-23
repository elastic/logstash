package org.logstash.execution;

import org.jruby.RubyArray;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.ext.JrubyEventExtLibrary;

import java.util.LinkedHashSet;

import static org.logstash.RubyUtil.RUBY;

public final class MemoryReadBatch implements QueueBatch {

    private final LinkedHashSet<IRubyObject> events;

    public MemoryReadBatch(final LinkedHashSet<IRubyObject> events) {
        this.events = events;
    }

    public static boolean isCancelled(final IRubyObject event) {
        return ((JrubyEventExtLibrary.RubyEvent) event).getEvent().isCancelled();
    }

    public static MemoryReadBatch create(LinkedHashSet<IRubyObject> events) {
        return new MemoryReadBatch(events);
    }

    public static MemoryReadBatch create() {
        return create(new LinkedHashSet<>());
    }

    @Override
    public RubyArray to_a() {
        ThreadContext context = RUBY.getCurrentContext();
        final RubyArray result = context.runtime.newArray(events.size());
        for (final IRubyObject event : events) {
            if (!isCancelled(event)) {
                result.add(event);
            }
        }
        return result;
    }

    @Override
    public void merge(final IRubyObject event) {
        events.add(event);
    }

    @Override
    public int filteredSize() {
        return events.size();
    }

    @Override
    public void close() {
        // no-op
    }
}
