package org.logstash.ackedqueue.ext;

import java.io.IOException;
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
import org.logstash.ext.JrubyEventExtLibrary;

@JRubyClass(name = "AckedBatch")
public final class RubyAckedBatch extends RubyObject {
    private static final long serialVersionUID = -3118949118637372130L;
    private Batch batch;

    public RubyAckedBatch(Ruby runtime, RubyClass klass) {
        super(runtime, klass);
    }

    public static RubyAckedBatch create(Ruby runtime, Batch batch) {
        final RubyAckedBatch ackedBatch =
            new RubyAckedBatch(runtime, RubyUtil.RUBY_ACKED_BATCH_CLASS);
        ackedBatch.batch = batch;
        return ackedBatch;
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
