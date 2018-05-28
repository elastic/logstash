package org.logstash.execution;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.UUID;
import org.apache.commons.codec.binary.Hex;
import org.jruby.Ruby;
import org.jruby.RubyBasicObject;
import org.jruby.RubyClass;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.common.DeadLetterQueueFactory;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.config.ir.ConfigCompiler;
import org.logstash.config.ir.PipelineIR;
import org.logstash.instrument.metrics.AbstractMetricExt;
import org.logstash.instrument.metrics.NullMetricExt;

@JRubyClass(name = "LogstashPipeline")
public final class LogstashPipelineExt extends RubyBasicObject {

    private final RubyString ephemeralId = RubyUtil.RUBY.newString(UUID.randomUUID().toString());

    private RubyString configString;

    private RubyString configHash;

    private IRubyObject settings;

    private IRubyObject pipelineSettings;

    private IRubyObject pipelineId;

    private AbstractMetricExt metric;

    private PipelineIR lir;

    private IRubyObject dlqWriter;

    public LogstashPipelineExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    public LogstashPipelineExt initialize(final ThreadContext context,
        final IRubyObject pipelineSettings, final IRubyObject namespacedMetric)
        throws NoSuchAlgorithmException, IncompleteSourceWithMetadataException {
        this.pipelineSettings = pipelineSettings;
        configString = (RubyString) pipelineSettings.callMethod(context, "config_string");
        configHash = context.runtime.newString(
            Hex.encodeHexString(
                MessageDigest.getInstance("SHA1").digest(configString.getBytes())
            )
        );
        this.settings = pipelineSettings.callMethod(context, "settings");
        final IRubyObject id = getSetting(context, "pipeline.id");
        if (id.isNil()) {
            pipelineId = id();
        } else {
            pipelineId = id;
        }
        if (namespacedMetric.isNil()) {
            metric = new NullMetricExt(context.runtime, RubyUtil.NULL_METRIC_CLASS).initialize(
                context, new IRubyObject[0]
            );
        } else {
            final AbstractMetricExt java = (AbstractMetricExt) namespacedMetric;
            if (getSetting(context, "metric.collect").isTrue()) {
                metric = java;
            } else {
                metric = new NullMetricExt(context.runtime, RubyUtil.NULL_METRIC_CLASS).initialize(
                    context, new IRubyObject[]{java.collector(context)}
                );
            }
        }
        lir = ConfigCompiler.configToPipelineIR(
            configString.asJavaString(),
            getSetting(context, "config.support_escapes").isTrue()
        );
        return this;
    }

    @JRubyMethod(name = "config_str")
    public RubyString configStr() {
        return configString;
    }

    @JRubyMethod(name = "config_hash")
    public RubyString configHash() {
        return configHash;
    }

    @JRubyMethod(name = "ephemeral_id")
    public RubyString ephemeralId() {
        return ephemeralId;
    }

    @JRubyMethod
    public IRubyObject settings() {
        return settings;
    }

    @JRubyMethod(name = "pipeline_config")
    public IRubyObject pipelineConfig() {
        return pipelineSettings;
    }

    @JRubyMethod(name = "pipeline_id")
    public IRubyObject pipelineId() {
        return pipelineId;
    }

    @JRubyMethod
    public AbstractMetricExt metric() {
        return metric;
    }

    @JRubyMethod
    public IRubyObject lir(final ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.runtime, lir);
    }

    @JRubyMethod(name = "dlq_writer")
    public IRubyObject dlqWriter(final ThreadContext context) {
        if (dlqWriter == null) {
            if (dlqEnabled(context).isTrue()) {
                dlqWriter = JavaUtil.convertJavaToUsableRubyObject(
                    context.runtime,
                    DeadLetterQueueFactory.getWriter(
                        pipelineId.asJavaString(),
                        getSetting(context, "path.dead_letter_queue").asJavaString(),
                        getSetting(context, "dead_letter_queue.max_bytes").convertToInteger()
                            .getLongValue()
                    )
                );
            } else {
                dlqWriter = RubyUtil.DUMMY_DLQ_WRITER_CLASS.callMethod(context, "new");
            }
        }
        return dlqWriter;
    }

    @JRubyMethod(name = "dlq_enabled?")
    public IRubyObject dlqEnabled(final ThreadContext context) {
        return getSetting(context, "dead_letter_queue.enable");
    }

    @JRubyMethod(name = "close_dlq_writer")
    public IRubyObject closeDlqWriter(final ThreadContext context) {
        dlqWriter.callMethod(context, "close");
        if (dlqEnabled(context).isTrue()) {
            DeadLetterQueueFactory.release(pipelineId.asJavaString());
        }
        return context.nil;
    }

    private IRubyObject getSetting(final ThreadContext context, final String name) {
        return settings.callMethod(context, "get_value", context.runtime.newString(name));
    }
}
