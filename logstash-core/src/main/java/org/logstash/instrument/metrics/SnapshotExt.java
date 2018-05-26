package org.logstash.instrument.metrics;

import org.jruby.Ruby;
import org.jruby.RubyBasicObject;
import org.jruby.RubyClass;
import org.jruby.RubyTime;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

@JRubyClass(name = "Snapshot")
public final class SnapshotExt extends RubyBasicObject {

    private IRubyObject metricStore;

    private RubyTime createdAt;

    public SnapshotExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(required = 1, optional = 1)
    public SnapshotExt initialize(final ThreadContext context, final IRubyObject[] args) {
        metricStore = args[0];
        if (args.length == 2) {
            createdAt = (RubyTime) args[1];
        } else {
            createdAt = (RubyTime) RubyTime.newInstance(context, context.runtime.getTime());
        }
        return this;
    }

    @JRubyMethod(name = "metric_store")
    public IRubyObject metricStore() {
        return metricStore;
    }

    @JRubyMethod(name = "created_at")
    public RubyTime createdAt() {
        return createdAt;
    }
}
