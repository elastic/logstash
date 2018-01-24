package org.logstash.ext;

import java.util.LinkedHashSet;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyEnumerator;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;

@JRubyClass(name = "MemoryReadBatch")
public final class JrubyMemoryReadBatchExt extends RubyObject {

    private final LinkedHashSet<IRubyObject> events;

    public JrubyMemoryReadBatchExt(final Ruby runtime, final RubyClass metaClass) {
        this(runtime, metaClass, new LinkedHashSet<>());
    }

    public JrubyMemoryReadBatchExt(final Ruby runtime, final RubyClass metaClass, final LinkedHashSet<IRubyObject> events) {
        super(runtime, metaClass);
        this.events = events;
    }

    public static boolean isCancelled(final IRubyObject event) {
        return ((JrubyEventExtLibrary.RubyEvent) event).getEvent().isCancelled();
    }

    public static JrubyMemoryReadBatchExt create(LinkedHashSet<IRubyObject> events) {
        JrubyMemoryReadBatchExt batch = new JrubyMemoryReadBatchExt(RubyUtil.RUBY,
                RubyUtil.MEMORY_READ_BATCH_CLASS, events);
        return batch;
    }

    public static JrubyMemoryReadBatchExt create() {
        return create(new LinkedHashSet<>());
    }

    @JRubyMethod(name = "to_a")
    public RubyArray toArray(final ThreadContext context) {
        final RubyArray result = context.runtime.newArray(events.size());
        for (final IRubyObject event : events) {
            if (!isCancelled(event)) {
                result.add(event);
            }
        }
        return result;
    }

    @JRubyMethod(required = 1)
    public IRubyObject merge(final ThreadContext context, final IRubyObject event) {
        events.add(event);
        return this;
    }

    @JRubyMethod(name = "filtered_size", alias = "size")
    public IRubyObject filteredSize(final ThreadContext context) {
        return context.runtime.newFixnum(events.size());
    }

    public int filteredSize() {
        return events.size();
    }

    @JRubyMethod
    public IRubyObject each(final ThreadContext context, final Block block) {
        if (!block.isGiven()) {
            return RubyEnumerator.enumeratorizeWithSize(
                context, this, "each", args -> getRuntime().newFixnum(events.size())
            );
        }
        for (final IRubyObject event : events) {
            if (!isCancelled(event)) {
                block.yield(context, event);
            }
        }
        return this;
    }
}
