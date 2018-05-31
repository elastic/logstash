package org.logstash.ackedqueue;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import org.jruby.Ruby;
import org.jruby.RubyBasicObject;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.ackedqueue.ext.JRubyWrappedAckedQueueExt;
import org.logstash.execution.AbstractWrappedQueueExt;
import org.logstash.ext.JrubyWrappedSynchronousQueueExt;

@JRubyClass(name = "QueueFactory")
public final class QueueFactoryExt extends RubyBasicObject {

    public QueueFactoryExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(meta = true)
    public static AbstractWrappedQueueExt create(final ThreadContext context, final IRubyObject recv,
        final IRubyObject settings) throws IOException {
        final String type = getSetting(context, settings, "queue.type").asJavaString();
        if ("persisted".equals(type)) {
            final Path queuePath = Paths.get(
                getSetting(context, settings, "path.queue").asJavaString(),
                getSetting(context, settings, "pipeline.id").asJavaString()
            );
            Files.createDirectories(queuePath);
            return new JRubyWrappedAckedQueueExt(context.runtime, RubyUtil.WRAPPED_ACKED_QUEUE_CLASS)
                .initialize(
                    context, new IRubyObject[]{
                        context.runtime.newString(queuePath.toString()),
                        getSetting(context, settings, "queue.page_capacity"),
                        getSetting(context, settings, "queue.max_events"),
                        getSetting(context, settings, "queue.checkpoint.writes"),
                        getSetting(context, settings, "queue.checkpoint.acks"),
                        getSetting(context, settings, "queue.checkpoint.interval"),
                        getSetting(context, settings, "queue.max_bytes")
                    }
                );
        } else if ("memory".equals(type)) {
            return new JrubyWrappedSynchronousQueueExt(
                context.runtime, RubyUtil.WRAPPED_SYNCHRONOUS_QUEUE_CLASS
            ).initialize(
                context, context.runtime.newFixnum(
                    getSetting(context, settings, "pipeline.batch.size")
                        .convertToInteger().getIntValue()
                        * getSetting(context, settings, "pipeline.workers")
                        .convertToInteger().getIntValue()
                )
            );
        } else {
            throw context.runtime.newRaiseException(
                RubyUtil.CONFIGURATION_ERROR_CLASS,
                String.format(
                    "Invalid setting `%s` for `queue.type`, supported types are: 'memory' or 'persisted'",
                    type
                )
            );
        }
    }

    private static IRubyObject getSetting(final ThreadContext context, final IRubyObject settings,
        final String name) {
        return settings.callMethod(context, "get_value", context.runtime.newString(name));
    }
}
