package org.logstash.instrument.metrics;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.RubySymbol;
import org.jruby.runtime.Block;
import org.jruby.runtime.JavaInternalBlockBody;
import org.jruby.runtime.Signature;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;

public class UserMetric {
    private UserMetric() {}

    private static Logger LOGGER = LogManager.getLogger(UserMetric.class);

    public static <USER_METRIC extends co.elastic.logstash.api.UserMetric<?>> USER_METRIC fromRubyBase(
            final AbstractNamespacedMetricExt metric,
            final RubySymbol key,
            final co.elastic.logstash.api.UserMetric.Factory<USER_METRIC> metricFactory
    ) {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();

        final Block metricSupplier = new Block(new JavaInternalBlockBody(context.runtime, Signature.NO_ARGUMENTS) {
            @Override
            public IRubyObject yield(ThreadContext threadContext, IRubyObject[] iRubyObjects) {
                return RubyUtil.toRubyObject(metricFactory.create(key.asJavaString()));
            }
        });

        final IRubyObject result = metric.register(context, key, metricSupplier);
        final Class<USER_METRIC> type = metricFactory.getType();
        if (!type.isAssignableFrom(result.getJavaClass())) {
            LOGGER.warn("UserMetric type mismatch for %s (expected: %s, received: %s); " +
                    "a null implementation will be substituted", key.asJavaString(), type, result.getJavaClass());
            return metricFactory.nullImplementation();
        }
        
        return result.toJava(type);
    }
}
