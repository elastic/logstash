package org.logstash.execution;

import org.jruby.Ruby;
import org.jruby.RubyBasicObject;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.ext.JRubyAbstractQueueWriteClientExt;

@JRubyClass(name = "AbstractWrappedQueue")
public abstract class AbstractWrappedQueueExt extends RubyBasicObject {

    public AbstractWrappedQueueExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(name = "write_client")
    public final JRubyAbstractQueueWriteClientExt writeClient(final ThreadContext context) {
        return getWriteClient(context);
    }

    @JRubyMethod(name = "read_client")
    public final IRubyObject readClient() {
        return getReadClient();
    }

    @JRubyMethod
    public final IRubyObject close(final ThreadContext context) {
        return doClose(context);
    }

    protected abstract IRubyObject doClose(ThreadContext context);

    protected abstract JRubyAbstractQueueWriteClientExt getWriteClient(ThreadContext context);

    protected abstract IRubyObject getReadClient();
}
