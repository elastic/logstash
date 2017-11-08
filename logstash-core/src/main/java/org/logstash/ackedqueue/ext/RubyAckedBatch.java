package org.logstash.ackedqueue.ext;

import java.io.IOException;
import java.util.Collection;
import java.util.List;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.Event;
import org.logstash.RubyUtil;
import org.logstash.ackedqueue.Batch;
import org.logstash.ackedqueue.Queueable;
import org.logstash.ackedqueue.io.LongVector;
import org.logstash.ext.JrubyEventExtLibrary;

@JRubyClass(name = "AckedBatch")
public final class RubyAckedBatch extends RubyObject {
    private static final long serialVersionUID = -3118949118637372130L;
    private Batch batch;

    public RubyAckedBatch(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }

    public RubyAckedBatch(Ruby runtime, Batch batch) {
        super(runtime, RubyUtil.RUBY_ACKED_BATCH_CLASS);
        this.batch = batch;
    }

    @SuppressWarnings("unchecked") // for the getList() calls
    @JRubyMethod(name = "initialize", required = 3)
    public IRubyObject ruby_initialize(ThreadContext context, IRubyObject events,
        IRubyObject seqNums, IRubyObject queue) {
        if (!(events instanceof RubyArray)) {
            context.runtime.newArgumentError("expected events array");
        }
        if (!(seqNums instanceof RubyArray)) {
            context.runtime.newArgumentError("expected seqNums array");
        }
        if (!(queue instanceof AbstractJRubyQueue.RubyAckedQueue)) {
            context.runtime.newArgumentError("expected queue AckedQueue");
        }
        final Collection<Long> seqList = (List<Long>) seqNums;
        final LongVector seqs = new LongVector(seqList.size());
        for (final long seq : seqList) {
            seqs.add(seq);
        }
        this.batch = new Batch((List<Queueable>) events, seqs,
            ((AbstractJRubyQueue.RubyAckedQueue) queue).getQueue()
        );
        return context.nil;
    }

    @JRubyMethod(name = "get_elements")
    public IRubyObject ruby_get_elements(ThreadContext context) {
        RubyArray result = context.runtime.newArray();
        this.batch.getElements().forEach(e -> result.add(
            JrubyEventExtLibrary.RubyEvent.newRubyEvent(context.runtime, (Event) e)));
        return result;
    }

    @JRubyMethod(name = "close")
    public IRubyObject ruby_close(ThreadContext context) {
        try {
            this.batch.close();
        } catch (IOException e) {
            throw RubyUtil.newRubyIOError(context.runtime, e);
        }
        return context.nil;
    }
}
