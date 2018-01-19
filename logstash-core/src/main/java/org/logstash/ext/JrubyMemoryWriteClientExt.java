package org.logstash.ext;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.java.proxies.JavaProxy;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.common.LsQueueUtils;

import java.util.Collection;
import java.util.concurrent.BlockingQueue;

@JRubyClass(name = "MemoryWriteClient")
public class JrubyMemoryWriteClientExt extends RubyObject {

    private BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue;

    public JrubyMemoryWriteClientExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    private JrubyMemoryWriteClientExt(final Ruby runtime, final RubyClass metaClass,
                                     BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue) {
        super(runtime, metaClass);
        this.queue = queue;
    }

    public static JrubyMemoryWriteClientExt create(
            BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue) {
        return new JrubyMemoryWriteClientExt(RubyUtil.RUBY,
                RubyUtil.MEMORY_WRITE_CLIENT_CLASS, queue);
    }

    @JRubyMethod(name = "initialize")
    @SuppressWarnings("unchecked")
    public void rubyInitialize(final ThreadContext context, IRubyObject queue) {
        this.queue =
                (BlockingQueue<JrubyEventExtLibrary.RubyEvent>) (((JavaProxy) queue).getObject());
    }

    @JRubyMethod(name = {"push", "<<"}, required = 1)
    public IRubyObject rubyPush(final ThreadContext context, IRubyObject event)
            throws InterruptedException {
        queue.put((JrubyEventExtLibrary.RubyEvent) event);
        return this;
    }

    @JRubyMethod(name = "push_batch", required = 1)
    public IRubyObject rubyPushBatch(final ThreadContext context, IRubyObject batch)
            throws InterruptedException {
        Collection<JrubyEventExtLibrary.RubyEvent> typedBatch =
                (Collection<JrubyEventExtLibrary.RubyEvent>)batch;
        LsQueueUtils.addAll(queue, typedBatch);
        return this;
    }

}
