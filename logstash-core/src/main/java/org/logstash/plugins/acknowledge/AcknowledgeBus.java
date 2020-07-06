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

package org.logstash.plugins.acknowledge;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import co.elastic.logstash.api.Acknowledgable;
import co.elastic.logstash.api.AcknowledgablePlugin;
import co.elastic.logstash.api.AcknowledgeTokenFactory;

import java.util.Collection;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.BiFunction;

/**
 * This class is the communication bus for the `pipeline` inputs and outputs to
 * talk to each other.
 *
 * This class is threadsafe.
 */
public class AcknowledgeBus implements co.elastic.logstash.api.AcknowledgeBus {

    final ConcurrentHashMap<String, AcknowledgablePlugin> acknowledgeIdMapping = new ConcurrentHashMap<>();
    private static final Logger logger = LogManager.getLogger(AcknowledgeBus.class);

    @Override
    public void acknowledgeEvents(final Collection<? extends Acknowledgable> events) {
        logger.debug("Received acknowledgeEvents for {} events", events.size());
        this.proccessEvents(events, AcknowledgablePlugin::acknowledge, "acknowledgeEvents");
    }

    @Override
    public void notifyClonedEvents(final Collection<? extends Acknowledgable> events) {
        logger.debug("Received notifyClonedEvents for {} events", events.size());
        this.proccessEvents(events, AcknowledgablePlugin::notifyCloned, "notifyClonedEvents");
    }

    private void proccessEvents(final Collection<? extends Acknowledgable> events,
            BiFunction<AcknowledgablePlugin, String, Boolean> processId, String processName) {
        if (events.isEmpty())
            return; // This can happen on pipeline shutdown or in some other situations

        long acknowledgeCount = events.stream().map(Acknowledgable::getAcknowledgeToken).filter(token -> token != null)
                .map(token -> {
                    final AcknowledgablePlugin plugin = acknowledgeIdMapping.get(token.getPluginId());
                    if (plugin != null) {
                        logger.debug("Plugin: {} Token: {}", token.getPluginId(), token.getAcknowledgeId());
                        if (!processId.apply(plugin, token.getAcknowledgeId())) {
                            logger.warn("{} for plugin: {} was unsuccesful for id: {}", processName, plugin.getId(),
                                    token.getAcknowledgeId());
                        }
                    } else {
                        logger.warn("Received {} for unknown plugin: {}", processName, token.getPluginId());
                    }
                    return null;
                }).count();
        logger.debug("Proccessed {} events succesfully for {} ", acknowledgeCount, processName);
    }

    /**
     * Should be called by a plugin on register
     *
     * @param plugin plugin to be registered
     * @return an AcknowledgeTokenGenerator instance is succefully registerd
     *         otherwise null is returned
     */
    @Override
    public AcknowledgeTokenFactory registerPlugin(final AcknowledgablePlugin plugin) {
        synchronized (plugin) {
            if (acknowledgeIdMapping.containsKey(plugin.getId())) {
                return null;
            }
            acknowledgeIdMapping.put(plugin.getId(), plugin);
            return id -> new AcknowledgeTokenImpl(plugin.getId(), id);
        }
    }

    /**
     * Should be called by an plugin on close
     *
     * @param plugin output that will be unregistered
     */
    @Override
    public boolean unregisterPlugin(final AcknowledgablePlugin plugin) {
        synchronized (plugin) {
            return acknowledgeIdMapping.remove(plugin.getId()) != null;
        }
    }

}
