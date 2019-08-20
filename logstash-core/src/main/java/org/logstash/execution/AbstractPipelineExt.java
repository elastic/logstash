package org.logstash.execution;

import java.io.IOException;
import java.nio.file.FileStore;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.UUID;
import org.apache.commons.codec.binary.Hex;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyBasicObject;
import org.jruby.RubyClass;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.ackedqueue.QueueFactoryExt;
import org.logstash.ackedqueue.ext.JRubyAckedQueueExt;
import org.logstash.ackedqueue.ext.JRubyWrappedAckedQueueExt;
import org.logstash.common.DeadLetterQueueFactory;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.config.ir.ConfigCompiler;
import org.logstash.config.ir.PipelineIR;
import org.logstash.ext.JRubyAbstractQueueWriteClientExt;
import org.logstash.ext.JRubyWrappedWriteClientExt;
import org.logstash.instrument.metrics.AbstractMetricExt;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.MetricKeys;
import org.logstash.instrument.metrics.NullMetricExt;
import org.logstash.secret.store.SecretStore;
import org.logstash.secret.store.SecretStoreExt;

@JRubyClass(name = "AbstractPipeline")
public class AbstractPipelineExt extends RubyBasicObject {

    private static final long serialVersionUID = 1L;

    private static final Logger LOGGER = LogManager.getLogger(AbstractPipelineExt.class);

    private static final @SuppressWarnings("rawtypes") RubyArray CAPACITY_NAMESPACE =
        RubyArray.newArray(RubyUtil.RUBY, RubyUtil.RUBY.newSymbol("capacity"));

    private static final @SuppressWarnings("rawtypes") RubyArray DATA_NAMESPACE =
        RubyArray.newArray(RubyUtil.RUBY, RubyUtil.RUBY.newSymbol("data"));

    private static final RubySymbol PAGE_CAPACITY_IN_BYTES =
        RubyUtil.RUBY.newSymbol("page_capacity_in_bytes");

    private static final RubySymbol MAX_QUEUE_SIZE_IN_BYTES =
        RubyUtil.RUBY.newSymbol("max_queue_size_in_bytes");

    private static final RubySymbol MAX_QUEUE_UNREAD_EVENTS =
        RubyUtil.RUBY.newSymbol("max_unread_events");

    private static final RubySymbol QUEUE_SIZE_IN_BYTES =
        RubyUtil.RUBY.newSymbol("queue_size_in_bytes");

    private static final RubySymbol FREE_SPACE_IN_BYTES =
        RubyUtil.RUBY.newSymbol("free_space_in_bytes");

    private static final RubySymbol STORAGE_TYPE = RubyUtil.RUBY.newSymbol("storage_type");

    private static final RubySymbol PATH = RubyUtil.RUBY.newSymbol("path");

    private static final RubySymbol TYPE_KEY = RubyUtil.RUBY.newSymbol("type");

    private static final RubySymbol QUEUE_KEY = RubyUtil.RUBY.newSymbol("queue");

    private static final RubySymbol DLQ_KEY = RubyUtil.RUBY.newSymbol("dlq");

    private static final @SuppressWarnings("rawtypes") RubyArray EVENTS_METRIC_NAMESPACE = RubyArray.newArray(
        RubyUtil.RUBY, new IRubyObject[]{MetricKeys.STATS_KEY, MetricKeys.EVENTS_KEY}
    );

    protected PipelineIR lir;

    private final RubyString ephemeralId = RubyUtil.RUBY.newString(UUID.randomUUID().toString());

    private AbstractNamespacedMetricExt dlqMetric;

    private RubyString configString;

    private RubyString configHash;

    private IRubyObject settings;

    private IRubyObject pipelineSettings;

    private IRubyObject pipelineId;

    private AbstractMetricExt metric;

    private IRubyObject dlqWriter;

    private PipelineReporterExt reporter;

    private AbstractWrappedQueueExt queue;

    private JRubyAbstractQueueWriteClientExt inputQueueClient;

    private QueueReadClientBase filterQueueClient;

    public AbstractPipelineExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    public final AbstractPipelineExt initialize(final ThreadContext context,
        final IRubyObject pipelineConfig, final IRubyObject namespacedMetric,
        final IRubyObject rubyLogger)
        throws NoSuchAlgorithmException, IncompleteSourceWithMetadataException {
        reporter = new PipelineReporterExt(
            context.runtime, RubyUtil.PIPELINE_REPORTER_CLASS).initialize(context, rubyLogger, this
        );
        pipelineSettings = pipelineConfig;
        configString = (RubyString) pipelineSettings.callMethod(context, "config_string");
        configHash = context.runtime.newString(
            Hex.encodeHexString(
                MessageDigest.getInstance("SHA1").digest(configString.getBytes())
            )
        );
        settings = pipelineSettings.callMethod(context, "settings");
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

    /**
     * queue opening needs to happen out of the the initialize method because the
     * AbstractPipeline is used for pipeline config validation and the queue
     * should not be opened for this. This should be called only in the actual
     * Pipeline/JavaPipeline initialisation.
     * @param context ThreadContext
     * @return Nil
     */
    @JRubyMethod(name = "open_queue")
    public final IRubyObject openQueue(final ThreadContext context) {
        try {
            queue = QueueFactoryExt.create(context, null, settings);
        } catch (final Exception ex) {
            LOGGER.error("Logstash failed to create queue.", ex);
            throw new IllegalStateException(ex);
        }
        inputQueueClient = queue.writeClient(context);
        filterQueueClient = queue.readClient();

        filterQueueClient.setEventsMetric(metric.namespace(context, EVENTS_METRIC_NAMESPACE));
        filterQueueClient.setPipelineMetric(
            metric.namespace(
                context,
                RubyArray.newArray(
                    context.runtime,
                    new IRubyObject[]{
                        MetricKeys.STATS_KEY, MetricKeys.PIPELINES_KEY,
                        pipelineId.convertToString().intern(), MetricKeys.EVENTS_KEY
                    }
                )
            )
        );

        return context.nil;
    }

    @JRubyMethod(name = "filter_queue_client")
    public final QueueReadClientBase filterQueueClient() {
        return filterQueueClient;
    }

    @JRubyMethod(name = "config_str")
    public final RubyString configStr() {
        return configString;
    }

    @JRubyMethod(name = "config_hash")
    public final RubyString configHash() {
        return configHash;
    }

    @JRubyMethod(name = "ephemeral_id")
    public final RubyString ephemeralId() {
        return ephemeralId;
    }

    @JRubyMethod
    public final IRubyObject settings() {
        return settings;
    }

    @JRubyMethod(name = "pipeline_config")
    public final IRubyObject pipelineConfig() {
        return pipelineSettings;
    }

    @JRubyMethod(name = "pipeline_id")
    public final IRubyObject pipelineId() {
        return pipelineId;
    }

    @JRubyMethod
    public final AbstractMetricExt metric() {
        return metric;
    }

    @JRubyMethod
    public final IRubyObject lir(final ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.runtime, lir);
    }

    @JRubyMethod(name = "dlq_writer")
    public final IRubyObject dlqWriter(final ThreadContext context) {
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
    public final IRubyObject dlqEnabled(final ThreadContext context) {
        return getSetting(context, "dead_letter_queue.enable");
    }

    @JRubyMethod(name = "close_dlq_writer")
    public final IRubyObject closeDlqWriter(final ThreadContext context) {
        dlqWriter.callMethod(context, "close");
        if (dlqEnabled(context).isTrue()) {
            DeadLetterQueueFactory.release(pipelineId.asJavaString());
        }
        return context.nil;
    }

    @JRubyMethod
    public final PipelineReporterExt reporter() {
        return reporter;
    }

    @JRubyMethod(name = "collect_dlq_stats")
    public final IRubyObject collectDlqStats(final ThreadContext context) {
        if (dlqEnabled(context).isTrue()) {
            getDlqMetric(context).gauge(
                context, QUEUE_SIZE_IN_BYTES,
                dlqWriter(context).callMethod(context, "get_current_queue_size")
            );
        }
        return context.nil;
    }

    @JRubyMethod(name = "system?")
    public final IRubyObject isSystem(final ThreadContext context) {
        return getSetting(context, "pipeline.system");
    }

    @JRubyMethod(name = "configured_as_reloadable?")
    public final IRubyObject isConfiguredReloadable(final ThreadContext context) {
        return getSetting(context, "pipeline.reloadable");
    }

    @JRubyMethod(name = "collect_stats")
    public final IRubyObject collectStats(final ThreadContext context) throws IOException {
        final AbstractNamespacedMetricExt pipelineMetric = metric.namespace(
            context,
            RubyArray.newArray(
                context.runtime,
                Arrays.asList(MetricKeys.STATS_KEY, MetricKeys.PIPELINES_KEY, pipelineId.asString().intern(), QUEUE_KEY)
            )
        );
        pipelineMetric.gauge(context, TYPE_KEY, getSetting(context, "queue.type"));
        if (queue instanceof JRubyWrappedAckedQueueExt) {
            final JRubyAckedQueueExt inner = ((JRubyWrappedAckedQueueExt) queue).rubyGetQueue();
            final RubyString dirPath = inner.ruby_dir_path(context);
            final AbstractNamespacedMetricExt capacityMetrics =
                pipelineMetric.namespace(context, CAPACITY_NAMESPACE);
            capacityMetrics.gauge(
                context, PAGE_CAPACITY_IN_BYTES, inner.ruby_page_capacity(context)
            );
            capacityMetrics.gauge(
                context, MAX_QUEUE_SIZE_IN_BYTES, inner.ruby_max_size_in_bytes(context)
            );
            capacityMetrics.gauge(
                context, MAX_QUEUE_UNREAD_EVENTS, inner.ruby_max_unread_events(context)
            );
            capacityMetrics.gauge(
                context, QUEUE_SIZE_IN_BYTES, inner.ruby_persisted_size_in_bytes(context)
            );
            final AbstractNamespacedMetricExt dataMetrics =
                pipelineMetric.namespace(context, DATA_NAMESPACE);
            final FileStore fileStore = Files.getFileStore(Paths.get(dirPath.asJavaString()));
            dataMetrics.gauge(
                context, FREE_SPACE_IN_BYTES,
                context.runtime.newFixnum(fileStore.getUnallocatedSpace())
            );
            dataMetrics.gauge(context, STORAGE_TYPE, context.runtime.newString(fileStore.type()));
            dataMetrics.gauge(context, PATH, dirPath);
            pipelineMetric.gauge(context, MetricKeys.EVENTS_KEY, inner.ruby_unread_count(context));
        }
        return context.nil;
    }

    @JRubyMethod(name = "input_queue_client")
    public final JRubyAbstractQueueWriteClientExt inputQueueClient() {
        return inputQueueClient;
    }

    @JRubyMethod
    public final AbstractWrappedQueueExt queue() {
        return queue;
    }

    @JRubyMethod
    public final IRubyObject close(final ThreadContext context) throws IOException {
        filterQueueClient.close();
        queue.close(context);
        closeDlqWriter(context);
        return context.nil;
    }

    @JRubyMethod(name = "wrapped_write_client", visibility = Visibility.PROTECTED)
    public final JRubyWrappedWriteClientExt wrappedWriteClient(final ThreadContext context,
        final IRubyObject pluginId) {
        return new JRubyWrappedWriteClientExt(context.runtime, RubyUtil.WRAPPED_WRITE_CLIENT_CLASS)
            .initialize(inputQueueClient, pipelineId.asJavaString(), metric, pluginId);
    }

    protected final IRubyObject getSetting(final ThreadContext context, final String name) {
        return getSetting(context, settings, name);
    }

    protected final boolean hasSetting(final ThreadContext context, final String name) {
        return hasSetting(context, settings, name);
    }

    private IRubyObject getSetting(final ThreadContext context, IRubyObject settings, final String name) {
        return settings.callMethod(context, "get_value", context.runtime.newString(name));
    }

    private boolean hasSetting(final ThreadContext context, final IRubyObject settings, final String name) {
        return settings.callMethod(context, "registered?", context.runtime.newString(name)) == context.tru;
    }

    protected SecretStore getSecretStore(final ThreadContext context) {
        IRubyObject settings = context.runtime.evalScriptlet("LogStash::SETTINGS");
        String keystoreFile = hasSetting(context, settings, "keystore.file")
                ? getSetting(context, settings, "keystore.file").asJavaString()
                : null;
        String keystoreClassname = hasSetting(context, settings, "keystore.classname")
                ? getSetting(context, settings, "keystore.classname").asJavaString()
                : null;
        return (keystoreFile != null && keystoreClassname != null)
                ? SecretStoreExt.getIfExists(keystoreFile, keystoreClassname)
                : null;
    }

    private AbstractNamespacedMetricExt getDlqMetric(final ThreadContext context) {
        if (dlqMetric == null) {
            dlqMetric = metric.namespace(
                context, RubyArray.newArray(
                    context.runtime,
                    Arrays.asList(
                        MetricKeys.STATS_KEY, MetricKeys.PIPELINES_KEY,
                        pipelineId.asString().intern(), DLQ_KEY
                    )
                )
            );
        }
        return dlqMetric;
    }
}
