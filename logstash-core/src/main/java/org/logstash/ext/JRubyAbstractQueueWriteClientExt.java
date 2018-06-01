package org.logstash.ext;

import java.util.Collection;
import org.jruby.Ruby;
import org.jruby.RubyBasicObject;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

@JRubyClass(name = "AbstractQueueWriteClient")
public abstract class JRubyAbstractQueueWriteClientExt extends RubyBasicObject {

    protected JRubyAbstractQueueWriteClientExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(name = {"push", "<<"}, required = 1)
    public final JRubyAbstractQueueWriteClientExt rubyPush(final ThreadContext context,
        final IRubyObject event) throws InterruptedException {
        doPush(context, (JrubyEventExtLibrary.RubyEvent) event);
        return this;
    }

    @SuppressWarnings("unchecked")
    @JRubyMethod(name = "push_batch", required = 1)
    public final JRubyAbstractQueueWriteClientExt rubyPushBatch(final ThreadContext context,
        final IRubyObject batch) throws InterruptedException {
        doPushBatch(context, (Collection<JrubyEventExtLibrary.RubyEvent>) batch);
        return this;
    }

    protected abstract JRubyAbstractQueueWriteClientExt doPush(ThreadContext context,
        JrubyEventExtLibrary.RubyEvent event) throws InterruptedException;

    protected abstract JRubyAbstractQueueWriteClientExt doPushBatch(ThreadContext context,
        Collection<JrubyEventExtLibrary.RubyEvent> batch) throws InterruptedException;
}
