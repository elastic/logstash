package org.logstash.ext;

import java.util.Collection;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyEnumerator;
import org.jruby.RubyHash;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.ackedqueue.ext.RubyAckedBatch;

@JRubyClass(name = "AckedReadBatch")
public final class JrubyAckedReadBatchExt extends RubyObject {

    private RubyAckedBatch ackedBatch;

    private RubyHash originals;

    private RubyHash generated;

    public JrubyAckedReadBatchExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    public static JrubyAckedReadBatchExt create(final ThreadContext context,
        final IRubyObject queue, final IRubyObject size, final IRubyObject timeout) {
        final JrubyAckedReadBatchExt batch =
            new JrubyAckedReadBatchExt(context.runtime, RubyUtil.ACKED_READ_BATCH_CLASS);
        return (JrubyAckedReadBatchExt) batch.ruby_initialize(context, queue, size, timeout);
    }

    @JRubyMethod(name = "initialize", required = 3)
    public IRubyObject ruby_initialize(final ThreadContext context, final IRubyObject queue,
        final IRubyObject size, final IRubyObject timeout) {
        final IRubyObject batch =
            queue.callMethod(context, "read_batch", new IRubyObject[]{size, timeout});
        if (batch.isNil()) {
            originals = RubyHash.newHash(context.runtime);
            ackedBatch = null;
        } else {
            ackedBatch = (RubyAckedBatch) batch;
            originals = (RubyHash) ackedBatch.ruby_get_elements(context);
        }
        generated = RubyHash.newHash(context.runtime);
        return this;
    }

    @JRubyMethod
    public IRubyObject merge(final ThreadContext context, final IRubyObject event) {
        if (!event.isNil() && !originals.containsKey(event)) {
            generated.put(event, context.tru);
        }
        return this;
    }

    @JRubyMethod(name = "to_a")
    public RubyArray toArray(final ThreadContext context) {
        final RubyArray result = context.runtime.newArray(filteredSize());
        for (final JrubyEventExtLibrary.RubyEvent event
            : (Collection<JrubyEventExtLibrary.RubyEvent>) originals.keys()) {
            if (!JrubyMemoryReadBatchExt.isCancelled(event)) {
                result.add(event);
            }
        }
        for (final JrubyEventExtLibrary.RubyEvent event
            : (Collection<JrubyEventExtLibrary.RubyEvent>) generated.keys()) {
            if (!JrubyMemoryReadBatchExt.isCancelled(event)) {
                result.add(event);
            }
        }
        return result;
    }

    @JRubyMethod
    public IRubyObject each(final ThreadContext context, final Block block) {
        if (!block.isGiven()) {
            return RubyEnumerator.enumeratorizeWithSize(
                context, this, "each", args -> getRuntime().newFixnum(filteredSize())
            );
        }
        for (final JrubyEventExtLibrary.RubyEvent event :
            (Collection<JrubyEventExtLibrary.RubyEvent>) originals.keys()) {
            if (!JrubyMemoryReadBatchExt.isCancelled(event)) {
                block.yield(context, event);
            }
        }
        for (final JrubyEventExtLibrary.RubyEvent event :
            (Collection<JrubyEventExtLibrary.RubyEvent>) generated.keys()) {
            if (!JrubyMemoryReadBatchExt.isCancelled(event)) {
                block.yield(context, event);
            }
        }
        return this;
    }

    @JRubyMethod
    public IRubyObject close(final ThreadContext context) {
        if (ackedBatch != null) {
            ackedBatch.ruby_close(context);
        }
        return this;
    }

    @JRubyMethod(name = {"size", "filtered_size"})
    public IRubyObject rubySize(final ThreadContext context) {
        return context.runtime.newFixnum(filteredSize());
    }

    @JRubyMethod(name = "starting_size")
    public IRubyObject rubyStartingSize(final ThreadContext context) {
        return context.runtime.newFixnum(originals.size());
    }

    public int filteredSize() {
        return originals.size() + generated.size();
    }
}
