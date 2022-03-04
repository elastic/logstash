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


package org.logstash.plugins;

import co.elastic.logstash.api.*;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.log.DefaultDeprecationLogger;

/**
 * Default implementation of Logstash Plugin's {@link Context}
 * */
public class ContextImpl implements Context {

    private DeadLetterQueueWriter dlqWriter;

    /**
     * This is a reference to the [stats, pipelines, *name*, plugins] metric namespace.
     */
    private Metric pluginsScopedMetric;

    public ContextImpl(DeadLetterQueueWriter dlqWriter, Metric metric) {
        this.dlqWriter = dlqWriter;
        this.pluginsScopedMetric = metric;
    }

    @Override
    public DeadLetterQueueWriter getDlqWriter() {
        return dlqWriter;
    }

    @Override
    public NamespacedMetric getMetric(Plugin plugin) {
        return pluginsScopedMetric.namespace(PluginLookup.PluginType.getTypeByPlugin(plugin).metricNamespace(), plugin.getId());
    }

    @Override
    public Logger getLogger(Plugin plugin) {
        return LogManager.getLogger(plugin.getClass());
    }

    @Override
    public DeprecationLogger getDeprecationLogger(Plugin plugin) {
        return new DefaultDeprecationLogger(getLogger(plugin));
    }

    @Override
    public EventFactory getEventFactory() {
        return BasicEventFactory.INSTANCE;
    }
}
