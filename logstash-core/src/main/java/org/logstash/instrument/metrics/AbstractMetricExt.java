package org.logstash.instrument.metrics;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

@JRubyClass(name = "AbstractMetric")
public abstract class AbstractMetricExt extends RubyObject {

    public AbstractMetricExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    public final AbstractNamespacedMetricExt namespace(final ThreadContext context,
        final IRubyObject name) {
        return createNamespaced(context, name);
    }

    @JRubyMethod
    public final IRubyObject collector(final ThreadContext context) {
        return getCollector(context);
    }

    protected abstract AbstractNamespacedMetricExt createNamespaced(
        ThreadContext context, IRubyObject name
    );

    protected abstract IRubyObject getCollector(ThreadContext context);
}
