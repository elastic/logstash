/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.execution;

import java.io.IOException;
import java.nio.file.FileStore;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.temporal.ChronoUnit;
import java.time.temporal.TemporalUnit;
import java.util.ArrayList;
import java.time.Duration;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.TimeUnit;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import com.google.common.annotations.VisibleForTesting;
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
import org.logstash.common.EnvironmentVariableProvider;
import org.logstash.common.SourceWithMetadata;
import org.logstash.common.io.DeadLetterQueueWriter;
import org.logstash.common.io.QueueStorageType;
import org.logstash.config.ir.ConfigCompiler;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.PipelineConfig;
import org.logstash.config.ir.PipelineIR;
import org.logstash.ext.JRubyAbstractQueueWriteClientExt;
import org.logstash.ext.JRubyWrappedWriteClientExt;
import org.logstash.instrument.metrics.AbstractMetricExt;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.FlowMetric;
import org.logstash.instrument.metrics.Metric;
import org.logstash.instrument.metrics.NullMetricExt;
import org.logstash.instrument.metrics.UptimeMetric;
import org.logstash.instrument.metrics.counter.LongCounter;
import org.logstash.plugins.ConfigVariableExpander;
import org.logstash.secret.store.SecretStore;
import org.logstash.secret.store.SecretStoreExt;

import static org.logstash.instrument.metrics.MetricKeys.*;

/**
 * JRuby extension to provide ancestor class for Ruby's Pipeline and JavaPipeline classes.
 * */
@JRubyClass(name = "AbstractPipeline")
public class AbstractPipelineExt extends RubyBasicObject {

    private static final long serialVersionUID = 1L;

    private static final Logger LOGGER = LogManager.getLogger(AbstractPipelineExt.class);

    private static final @SuppressWarnings("rawtypes") RubyArray CAPACITY_NAMESPACE =
        RubyArray.newArray(RubyUtil.RUBY, RubyUtil.RUBY.newSymbol("capacity"));

    private static final @SuppressWarnings("rawtypes") RubyArray DATA_NAMESPACE =
        RubyArray.newArray(RubyUtil.RUBY, RubyUtil.RUBY.newSymbol("data"));

    private static final @SuppressWarnings("rawtypes") RubyArray EVENTS_METRIC_NAMESPACE = RubyArray.newArray(
        RubyUtil.RUBY, new IRubyObject[]{STATS_KEY, EVENTS_KEY}
    );

    @SuppressWarnings("serial")
    protected PipelineIR lir;

    private final RubyString ephemeralId = RubyUtil.RUBY.newString(UUID.randomUUID().toString());

    private AbstractNamespacedMetricExt dlqMetric;

    private RubyString configString;

    @SuppressWarnings({"rawtypes", "serial"})
    private List<SourceWithMetadata> configParts;

    private RubyString configHash;

    private transient IRubyObject settings;

    private transient IRubyObject pipelineSettings;

    private transient IRubyObject pipelineId;

    private transient AbstractMetricExt metric;

    private transient IRubyObject dlqWriter;

    private PipelineReporterExt reporter;

    private AbstractWrappedQueueExt queue;

    private JRubyAbstractQueueWriteClientExt inputQueueClient;

    private QueueReadClientBase filterQueueClient;

    private ArrayList<FlowMetric> flowMetrics = new ArrayList<>();

    public AbstractPipelineExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    public final AbstractPipelineExt initialize(final ThreadContext context,
        final IRubyObject pipelineConfig, final IRubyObject namespacedMetric,
        final IRubyObject rubyLogger)
        throws NoSuchAlgorithmException {
        reporter = new PipelineReporterExt(
            context.runtime, RubyUtil.PIPELINE_REPORTER_CLASS).initialize(context, rubyLogger, this
        );
        pipelineSettings = pipelineConfig;
        configString = (RubyString) pipelineSettings.callMethod(context, "config_string");
        configParts = pipelineSettings.toJava(PipelineConfig.class).getConfigParts();
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
        boolean supportEscapes = getSetting(context, "config.support_escapes").isTrue();
        try (ConfigVariableExpander cve = new ConfigVariableExpander(getSecretStore(context), EnvironmentVariableProvider.defaultProvider())) {
            lir = ConfigCompiler.configToPipelineIR(configParts, supportEscapes, cve);
        } catch (InvalidIRException iirex) {
            throw new IllegalArgumentException(iirex);
        }
        return this;
    }

    /**
     * queue opening needs to happen out of the initialize method because the
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
                            STATS_KEY,
                            PIPELINES_KEY,
                            pipelineId.convertToString().intern(),
                            EVENTS_KEY
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
                final DeadLetterQueueWriter javaDlqWriter = createDeadLetterQueueWriterFromSettings(context);
                dlqWriter = JavaUtil.convertJavaToUsableRubyObject(context.runtime, javaDlqWriter);
            } else {
                dlqWriter = RubyUtil.DUMMY_DLQ_WRITER_CLASS.callMethod(context, "new");
            }
        }
        return dlqWriter;
    }

    private DeadLetterQueueWriter createDeadLetterQueueWriterFromSettings(ThreadContext context) {
        final QueueStorageType storageType = QueueStorageType.parse(getSetting(context, "dead_letter_queue.storage_policy").asJavaString());

        String dlqPath = getSetting(context, "path.dead_letter_queue").asJavaString();
        long dlqMaxBytes = getSetting(context, "dead_letter_queue.max_bytes").convertToInteger().getLongValue();
        Duration dlqFlushInterval = Duration.ofMillis(getSetting(context, "dead_letter_queue.flush_interval").convertToInteger().getLongValue());

        if (hasSetting(context, "dead_letter_queue.retain.age") && !getSetting(context, "dead_letter_queue.retain.age").isNil()) {
            // convert to Duration
            final Duration age = parseToDuration(getSetting(context, "dead_letter_queue.retain.age").convertToString().toString());
            return DeadLetterQueueFactory.getWriter(pipelineId.asJavaString(), dlqPath, dlqMaxBytes,
                    dlqFlushInterval, storageType, age);
        }

        return DeadLetterQueueFactory.getWriter(pipelineId.asJavaString(), dlqPath, dlqMaxBytes, dlqFlushInterval, storageType);
    }

    /**
     * Convert time strings like 3d or 4h or 5m to a duration
     * */
    @VisibleForTesting
    static Duration parseToDuration(String timeStr) {
        final Matcher matcher = Pattern.compile("(?<value>\\d+)\\s*(?<time>[dhms])").matcher(timeStr);
        if (!matcher.matches()) {
            throw new IllegalArgumentException("Expected a time specification in the form <number>[d,h,m,s], e.g. 3m, but found [" + timeStr + "]");
        }
        final int value = Integer.parseInt(matcher.group("value"));
        final String timeSpecifier = matcher.group("time");
        final TemporalUnit unit;
        switch (timeSpecifier) {
            case "d": unit = ChronoUnit.DAYS; break;
            case "h": unit = ChronoUnit.HOURS; break;
            case "m": unit = ChronoUnit.MINUTES; break;
            case "s": unit = ChronoUnit.SECONDS; break;
            default: throw new IllegalStateException("Expected a time unit specification from d,h,m,s but found: [" + timeSpecifier + "]");
        }
        return Duration.of(value, unit);
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
                    context,
                    QUEUE_SIZE_IN_BYTES_KEY,
                    dlqWriter(context).callMethod(context, "get_current_queue_size")
            );
            getDlqMetric(context).gauge(
                    context,
                    STORAGE_POLICY_KEY,
                    dlqWriter(context).callMethod(context, "get_storage_policy")
            );
            getDlqMetric(context).gauge(
                    context,
                    MAX_QUEUE_SIZE_IN_BYTES_KEY,
                    getSetting(context, "dead_letter_queue.max_bytes").convertToInteger());
            getDlqMetric(context).gauge(
                    context,
                    DROPPED_EVENTS_KEY,
                    dlqWriter(context).callMethod(context, "get_dropped_events")
            );
            getDlqMetric(context).gauge(
                    context,
                    LAST_ERROR_KEY,
                    dlqWriter(context).callMethod(context, "get_last_error")
            );
            getDlqMetric(context).gauge(
                    context,
                    EXPIRED_EVENTS_KEY,
                    dlqWriter(context).callMethod(context, "get_expired_events")
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
                Arrays.asList(
                        STATS_KEY,
                        PIPELINES_KEY,
                        pipelineId.asString().intern(),
                        QUEUE_KEY)));

        pipelineMetric.gauge(context, TYPE_KEY, getSetting(context, "queue.type"));
        if (queue instanceof JRubyWrappedAckedQueueExt) {
            final JRubyAckedQueueExt inner = ((JRubyWrappedAckedQueueExt) queue).rubyGetQueue();
            final RubyString dirPath = inner.ruby_dir_path(context);
            final AbstractNamespacedMetricExt capacityMetrics =
                pipelineMetric.namespace(context, CAPACITY_NAMESPACE);
            capacityMetrics.gauge(
                context, PAGE_CAPACITY_IN_BYTES_KEY, inner.ruby_page_capacity(context)
            );
            capacityMetrics.gauge(
                context, MAX_QUEUE_SIZE_IN_BYTES_KEY, inner.ruby_max_size_in_bytes(context)
            );
            capacityMetrics.gauge(
                context, MAX_QUEUE_UNREAD_EVENTS_KEY, inner.ruby_max_unread_events(context)
            );
            capacityMetrics.gauge(
                context, QUEUE_SIZE_IN_BYTES_KEY, inner.ruby_persisted_size_in_bytes(context)
            );
            final AbstractNamespacedMetricExt dataMetrics =
                pipelineMetric.namespace(context, DATA_NAMESPACE);
            final FileStore fileStore = Files.getFileStore(Paths.get(dirPath.asJavaString()));
            dataMetrics.gauge(
                context,
                FREE_SPACE_IN_BYTES_KEY,
                context.runtime.newFixnum(fileStore.getUnallocatedSpace())
            );
            dataMetrics.gauge(context, STORAGE_TYPE_KEY, context.runtime.newString(fileStore.type()));
            dataMetrics.gauge(context, PATH_KEY, dirPath);
            pipelineMetric.gauge(context, EVENTS_KEY, inner.ruby_unread_count(context));
        }
        return context.nil;
    }

    @JRubyMethod(name = "initialize_flow_metrics")
    public final IRubyObject initializeFlowMetrics(final ThreadContext context) {
        if (metric.collector(context).isNil()) { return context.nil; }

        final UptimeMetric uptimeInMillis = initOrGetUptimeMetric(context, buildNamespace(),
                RubyUtil.RUBY.newSymbol(UPTIME_IN_MILLIS_KEY.asJavaString()));
        final UptimeMetric uptimeInSeconds = uptimeInMillis.withTimeUnit(UPTIME_IN_SECONDS_KEY.asJavaString(),
                TimeUnit.SECONDS);

        final RubySymbol[] flowNamespace = buildNamespace(FLOW_KEY);
        final RubySymbol[] eventsNamespace = buildNamespace(EVENTS_KEY);

        final LongCounter eventsInCounter = initOrGetCounterMetric(context, eventsNamespace, IN_KEY);
        final FlowMetric inputThroughput = new FlowMetric(INPUT_THROUGHPUT_KEY.asJavaString(),
                eventsInCounter, uptimeInSeconds);
        this.flowMetrics.add(inputThroughput);
        storeMetric(context, flowNamespace, inputThroughput);

        final LongCounter eventsFilteredCounter = initOrGetCounterMetric(context, eventsNamespace, FILTERED_KEY);
        final FlowMetric filterThroughput = new FlowMetric(FILTER_THROUGHPUT_KEY.asJavaString(),
                eventsFilteredCounter, uptimeInSeconds);
        this.flowMetrics.add(filterThroughput);
        storeMetric(context, flowNamespace, filterThroughput);

        final LongCounter eventsOutCounter = initOrGetCounterMetric(context, eventsNamespace, OUT_KEY);
        final FlowMetric outputThroughput = new FlowMetric(OUTPUT_THROUGHPUT_KEY.asJavaString(),
                eventsOutCounter, uptimeInSeconds);
        this.flowMetrics.add(outputThroughput);
        storeMetric(context, flowNamespace, outputThroughput);

        final LongCounter queuePushWaitInMillis = initOrGetCounterMetric(context, eventsNamespace, PUSH_DURATION_KEY);
        final FlowMetric backpressureFlow = new FlowMetric(QUEUE_BACKPRESSURE_KEY.asJavaString(),
                queuePushWaitInMillis, uptimeInMillis);
        this.flowMetrics.add(backpressureFlow);
        storeMetric(context, flowNamespace, backpressureFlow);

        final LongCounter durationInMillis = initOrGetCounterMetric(context, eventsNamespace, DURATION_IN_MILLIS_KEY);
        final FlowMetric concurrencyFlow = new FlowMetric(WORKER_CONCURRENCY_KEY.asJavaString(),
                durationInMillis, uptimeInMillis);
        this.flowMetrics.add(concurrencyFlow);
        storeMetric(context, flowNamespace, concurrencyFlow);

        return context.nil;
    }

    @JRubyMethod(name = "collect_flow_metrics")
    public final IRubyObject collectFlowMetrics(final ThreadContext context) {
        this.flowMetrics.forEach(FlowMetric::capture);
        return context.nil;
    }

    LongCounter initOrGetCounterMetric(final ThreadContext context,
                                       final RubySymbol[] subPipelineNamespacePath,
                                       final RubySymbol metricName) {
        final IRubyObject collector = this.metric.collector(context);
        final IRubyObject fullNamespace = RubyArray.newArray(context.runtime, fullNamespacePath(subPipelineNamespacePath));

        final IRubyObject retrievedMetric = collector.callMethod(context, "get", new IRubyObject[]{fullNamespace, metricName, context.runtime.newSymbol("counter")});
        return retrievedMetric.toJava(LongCounter.class);
    }

    UptimeMetric initOrGetUptimeMetric(final ThreadContext context,
                                       final RubySymbol[] subPipelineNamespacePath,
                                       final RubySymbol uptimeMetricName) {
        final IRubyObject collector = this.metric.collector(context);
        final IRubyObject fullNamespace = RubyArray.newArray(context.runtime, fullNamespacePath(subPipelineNamespacePath));

        final IRubyObject retrievedMetric = collector.callMethod(context, "get", new IRubyObject[]{fullNamespace, uptimeMetricName, context.runtime.newSymbol("uptime")});
        return retrievedMetric.toJava(UptimeMetric.class);
    }

    <T> void storeMetric(final ThreadContext context,
                         final RubySymbol[] subPipelineNamespacePath,
                         final Metric<T> metric) {
        final IRubyObject collector = this.metric.collector(context);
        final IRubyObject fullNamespace = RubyArray.newArray(context.runtime, fullNamespacePath(subPipelineNamespacePath));
        final IRubyObject metricKey = context.runtime.newSymbol(metric.getName());

        final IRubyObject wasRegistered = collector.callMethod(context, "register?", new IRubyObject[]{fullNamespace, metricKey, JavaUtil.convertJavaToUsableRubyObject(context.runtime, metric)});
        if (!wasRegistered.toJava(Boolean.class)) {
            LOGGER.warn(String.format("Metric registration error: `%s` could not be registered in namespace `%s`", metricKey, fullNamespace));
        } else {
            LOGGER.debug(String.format("Flow metric registered: `%s` in namespace `%s`", metricKey, fullNamespace));
        }
    }

    RubySymbol[] fullNamespacePath(RubySymbol... subPipelineNamespacePath) {
        final RubySymbol[] pipelineNamespacePath = new RubySymbol[] { STATS_KEY, PIPELINES_KEY, pipelineId.asString().intern() };
        if (subPipelineNamespacePath.length == 0) {
            return pipelineNamespacePath;
        }
        final RubySymbol[] fullNamespacePath = Arrays.copyOf(pipelineNamespacePath, pipelineNamespacePath.length + subPipelineNamespacePath.length);
        System.arraycopy(subPipelineNamespacePath, 0, fullNamespacePath, pipelineNamespacePath.length, subPipelineNamespacePath.length);
        return fullNamespacePath;
    }

    RubySymbol[] buildNamespace(final RubySymbol... namespace) {
        return namespace;
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

    @JRubyMethod(name = "pipeline_source_details", visibility = Visibility.PROTECTED)
    @SuppressWarnings("rawtypes")
    public RubyArray getPipelineSourceDetails(final ThreadContext context) {
        List<RubyString> pipelineSources = new ArrayList<>(configParts.size());
        for (SourceWithMetadata sourceWithMetadata : configParts) {
            String protocol = sourceWithMetadata.getProtocol();
            switch (protocol) {
                case "string":
                    pipelineSources.add(RubyString.newString(context.runtime, "config string"));
                    break;
                case "file":
                    pipelineSources.add(RubyString.newString(context.runtime, sourceWithMetadata.getId()));
                    break;
                case "x-pack-metrics":
                    pipelineSources.add(RubyString.newString(context.runtime, "monitoring pipeline"));
                    break;
                case "x-pack-config-management":
                    pipelineSources.add(RubyString.newString(context.runtime, "central pipeline management"));
                    break;
                case "module":
                    pipelineSources.add(RubyString.newString(context.runtime, "module"));
                    break;
            }
        }
        return RubyArray.newArray(context.runtime, pipelineSources);
    }

    protected final IRubyObject getSetting(final ThreadContext context, final String name) {
        return settings.callMethod(context, "get_value", context.runtime.newString(name));
    }

    protected final boolean hasSetting(final ThreadContext context, final String name) {
        return settings.callMethod(context, "registered?", context.runtime.newString(name)) == context.tru;
    }

    protected SecretStore getSecretStore(final ThreadContext context) {
        String keystoreFile = hasSetting(context, "keystore.file")
                ? getSetting(context, "keystore.file").asJavaString()
                : null;
        String keystoreClassname = hasSetting(context, "keystore.classname")
                ? getSetting(context, "keystore.classname").asJavaString()
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
                            STATS_KEY,
                            PIPELINES_KEY,
                            pipelineId.asString().intern(),
                            DLQ_KEY)));
        }
        return dlqMetric;
    }
}
