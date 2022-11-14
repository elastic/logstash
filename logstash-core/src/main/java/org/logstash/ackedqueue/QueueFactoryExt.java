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
import org.jruby.Ruby;
import org.jruby.RubyBasicObject;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.ackedqueue.ext.JRubyWrappedAckedQueueExt;
import org.logstash.common.SettingKeyDefinitions;
import org.logstash.execution.AbstractWrappedQueueExt;
import org.logstash.ext.JrubyWrappedSynchronousQueueExt;

/**
 * Persistent queue factory JRuby extension.
 * */
@JRubyClass(name = "QueueFactory")
public final class QueueFactoryExt extends RubyBasicObject {

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

    public QueueFactoryExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(meta = true)
    public static AbstractWrappedQueueExt create(final ThreadContext context, final IRubyObject recv,
        final IRubyObject settings) throws IOException {
        final String type = getSetting(context, settings, QUEUE_TYPE_CONTEXT_NAME).asJavaString();
        if (PERSISTED_TYPE.equals(type)) {
            final Path queuePath = Paths.get(
                getSetting(context, settings, SettingKeyDefinitions.PATH_QUEUE).asJavaString(),
                getSetting(context, settings, SettingKeyDefinitions.PIPELINE_ID).asJavaString()
            );

            // Files.createDirectories raises a FileAlreadyExistsException
            // if pipeline queue path is a symlink, so worth checking against Files.exists
            if (Files.exists(queuePath) == false) {
                Files.createDirectories(queuePath);
            }

            return new JRubyWrappedAckedQueueExt(context.runtime, RubyUtil.WRAPPED_ACKED_QUEUE_CLASS)
                .initialize(
                    context, new IRubyObject[]{
                        context.runtime.newString(queuePath.toString()),
                        getSetting(context, settings, SettingKeyDefinitions.QUEUE_PAGE_CAPACITY),
                        getSetting(context, settings, SettingKeyDefinitions.QUEUE_MAX_EVENTS),
                        getSetting(context, settings, SettingKeyDefinitions.QUEUE_CHECKPOINT_WRITES),
                        getSetting(context, settings, SettingKeyDefinitions.QUEUE_CHECKPOINT_ACKS),
                        getSetting(context, settings, SettingKeyDefinitions.QUEUE_CHECKPOINT_INTERVAL),
                        getSetting(context, settings, SettingKeyDefinitions.QUEUE_CHECKPOINT_RETRY),
                        getSetting(context, settings, SettingKeyDefinitions.QUEUE_MAX_BYTES)
                    }
                );
        } else if (MEMORY_TYPE.equals(type)) {
            return new JrubyWrappedSynchronousQueueExt(
                context.runtime, RubyUtil.WRAPPED_SYNCHRONOUS_QUEUE_CLASS
            ).initialize(
                context, context.runtime.newFixnum(
                    getSetting(context, settings, SettingKeyDefinitions.PIPELINE_BATCH_SIZE)
                        .convertToInteger().getIntValue()
                        * getSetting(context, settings, SettingKeyDefinitions.PIPELINE_WORKERS)
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
