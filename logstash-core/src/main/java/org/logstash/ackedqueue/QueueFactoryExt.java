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


package org.logstash.ackedqueue;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import co.elastic.logstash.api.NamespacedMetric;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.Ruby;
import org.jruby.RubyBasicObject;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.api.Convert;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.Event;
import org.logstash.RubyUtil;
import org.logstash.ackedqueue.ext.JRubyWrappedAckedQueueExt;
import org.logstash.common.SettingKeyDefinitions;
import org.logstash.execution.AbstractWrappedQueueExt;
import org.logstash.ext.JrubyWrappedSynchronousQueueExt;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.plugins.NamespacedMetricImpl;

import static org.logstash.common.SettingKeyDefinitions.*;

/**
 * Persistent queue factory JRuby extension.
 * */
@JRubyClass(name = "QueueFactory")
public final class QueueFactoryExt extends RubyBasicObject {

    public enum BatchMetricMode {
        DISABLED,
        MINIMAL,
        FULL
    }

    /**
     * A static value to indicate Persistent Queue is enabled.
     */
    public static String PERSISTED_TYPE = "persisted";

    /**
     * A static value to indicate Memory Queue is enabled.
     */
    public static String MEMORY_TYPE = "memory";

    /**
     * A contextual name to expose the queue type.
     */
    public static String QUEUE_TYPE_CONTEXT_NAME = "queue.type";

    private static final long serialVersionUID = 1L;

    private static final Logger LOGGER = LogManager.getLogger(QueueFactoryExt.class);

    public QueueFactoryExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @Deprecated
    @JRubyMethod(meta = true)
    public static AbstractWrappedQueueExt create(final ThreadContext context, final IRubyObject recv,
                                                 final IRubyObject settings) throws IOException {
        return create(context, settings, null);
    }

    public static AbstractWrappedQueueExt create(final ThreadContext context,
                                                 final IRubyObject settings,
                                                 final AbstractNamespacedMetricExt metric) throws IOException {
        final String type = getSetting(context, settings, QUEUE_TYPE_CONTEXT_NAME).asJavaString();
        final BatchMetricMode batchMetricMode = decodeBatchMetricMode(context, settings);
        if (PERSISTED_TYPE.equals(type)) {
            final Settings queueSettings = extractQueueSettings(settings);
            final Path queuePath = Paths.get(queueSettings.getDirPath());

            // Files.createDirectories raises a FileAlreadyExistsException
            // if pipeline queue path is a symlink, so worth checking against Files.exists
            if (Files.exists(queuePath) == false) {
                Files.createDirectories(queuePath);
            }

            final NamespacedMetric namespacedMetric = getMetric(context, metric);
            return JRubyWrappedAckedQueueExt.create(context, queueSettings, namespacedMetric, batchMetricMode);

        } else if (MEMORY_TYPE.equals(type)) {
            final int batchSize = Convert.toInt(context,
                getSetting(context, settings, SettingKeyDefinitions.PIPELINE_BATCH_SIZE).convertToInteger()
            );
            final int workers = Convert.toInt(context,
                getSetting(context, settings, SettingKeyDefinitions.PIPELINE_WORKERS).convertToInteger()
            );
            int queueSize = batchSize * workers;
            return JrubyWrappedSynchronousQueueExt.create(context, queueSize, batchMetricMode);
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

    private static BatchMetricMode decodeBatchMetricMode(ThreadContext context, IRubyObject settings) {
        final String batchMetricModeStr = getSetting(context, settings, SettingKeyDefinitions.PIPELINE_BATCH_METRICS)
                .asJavaString();

        if (batchMetricModeStr == null || batchMetricModeStr.isEmpty()) {
            return BatchMetricMode.DISABLED;
        }
        return BatchMetricMode.valueOf(batchMetricModeStr.toUpperCase());
    }

    private static NamespacedMetric getMetric(final ThreadContext context, final AbstractNamespacedMetricExt metric) {
        if ( metric == null ) {
            return NamespacedMetricImpl.getNullMetric();
        }
        return new NamespacedMetricImpl(context, metric);
    }

    private static IRubyObject getSetting(final ThreadContext context, final IRubyObject settings,
        final String name) {
        return settings.callMethod(context, "get_value", context.runtime.newString(name));
    }

    private static Settings extractQueueSettings(final IRubyObject settings) {
        final ThreadContext context = settings.getRuntime().getCurrentContext();
        final Path queuePath = Paths.get(
                getSetting(context, settings, PATH_QUEUE).asJavaString(),
                getSetting(context, settings, PIPELINE_ID).asJavaString()
        );

        return SettingsImpl.fileSettingsBuilder(queuePath.toString())
                .elementClass(Event.class)
                .capacity(getSetting(context, settings, QUEUE_PAGE_CAPACITY).toJava(Integer.class))
                .maxUnread(getSetting(context, settings, QUEUE_MAX_EVENTS).toJava(Integer.class))
                .checkpointMaxWrites(getSetting(context, settings, QUEUE_CHECKPOINT_WRITES).toJava(Integer.class))
                .checkpointMaxAcks(getSetting(context, settings, QUEUE_CHECKPOINT_ACKS).toJava(Integer.class))
                .checkpointRetry(getSetting(context, settings, QUEUE_CHECKPOINT_RETRY).isTrue())
                .queueMaxBytes(getSetting(context, settings, QUEUE_MAX_BYTES).toJava(Long.class))
                .compressionCodecFactory(extractConfiguredCodec(settings))
                .build();
    }

    private static CompressionCodec.Factory extractConfiguredCodec(final IRubyObject settings) {
        final ThreadContext context = settings.getRuntime().getCurrentContext();
        final String compressionSetting = getSetting(context, settings, QUEUE_COMPRESSION).asJavaString();
        return CompressionCodec.fromConfigValue(compressionSetting, LOGGER);
    }
}
