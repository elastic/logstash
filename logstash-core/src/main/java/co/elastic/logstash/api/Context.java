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


package co.elastic.logstash.api;

import org.apache.logging.log4j.Logger;

/**
 * Provides Logstash context to plugins.
 */
public interface Context {

    /**
     * Provides a dead letter queue (DLQ) writer, if configured, to output plugins. If no DLQ writer
     * is configured or the plugin is not an output, {@code null} will be returned.
     * @return {@link DeadLetterQueueWriter} instance if available or {@code null} otherwise.
     */
    DeadLetterQueueWriter getDlqWriter();

    /**
     * Provides a metric namespace scoped to the given {@code plugin} that metrics can be written to and
     * can be nested deeper with further namespaces.
     * @param plugin The plugin the metric should be scoped to
     * @return       A metric scoped to the current plugin
     */
    NamespacedMetric getMetric(Plugin plugin);

    /**
     * Provides a {@link Logger} instance to plugins.
     * @param plugin The plugin for which the logger should be supplied.
     * @return       The supplied Logger instance.
     */
    Logger getLogger(Plugin plugin);

    /**
     * Provides a {@link Logger} instance to plugins.
     * @param plugin The plugin for which the logger should be supplied.
     * @return       The supplied Logger instance.
     */
    DeprecationLogger getDeprecationLogger(Plugin plugin);

    /**
     * Provides an {@link EventFactory} to constructs instance of {@link Event}.
     * @return The event factory.
     */
    EventFactory getEventFactory();

}
