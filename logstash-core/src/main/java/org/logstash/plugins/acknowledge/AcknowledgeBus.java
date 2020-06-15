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
import co.elastic.logstash.api.AcknowledgeToken;
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
    volatile boolean blockOnUnlisten = false;
    private static final Logger logger = LogManager.getLogger(AcknowledgeBus.class);

    private final class AcknowledgeTokenImpl implements AcknowledgeToken {
        private final String pluginId;
        private final String acknowledgeId;

        AcknowledgeTokenImpl(final String pluginId, final String acknowledgeId) {
            if (pluginId == null)
                throw new IllegalArgumentException("pluginId cannot be null");
            if (acknowledgeId == null)
                throw new IllegalArgumentException("acknowledgeId cannot be null");
            this.pluginId = pluginId;
            this.acknowledgeId = acknowledgeId;
        }

        @Override
        public String getPluginId() {
            return pluginId;
        }

        @Override
        public String getAcknowledgeId() {
            return acknowledgeId;
        }

        @Override
        public boolean equals(final Object o) {
            if (o == this)
                return true;
            if (!(o instanceof AcknowledgeToken))
                return false;
            final AcknowledgeTokenImpl other = (AcknowledgeTokenImpl) o;
            if (!other.canEqual((Object) this))
                return false;
            if (this.getPluginId() == null ? other.getPluginId() != null
                    : !this.getPluginId().equals(other.getPluginId()))
                return false;
            if (this.getAcknowledgeId() == null ? other.getAcknowledgeId() != null
                    : !this.getAcknowledgeId().equals(other.getAcknowledgeId()))
                return false;
            return true;
        }

        protected boolean canEqual(final Object other) {
            return other instanceof AcknowledgeTokenImpl;
        }

        @Override
        public int hashCode() {
            final int PRIME = 59;
            int result = 1;
            result = (result * PRIME) + (this.pluginId == null ? 43 : this.pluginId.hashCode());
            result = (result * PRIME) + (this.acknowledgeId == null ? 43 : this.acknowledgeId.hashCode());
            return result;
        }

    }

    @Override
    public void acknowledgeEvents(final Collection<? extends Acknowledgable> events) {
        this.proccessEvents(events, AcknowledgablePlugin::acknowledge, "Acknowledge");
    }

    @Override
    public void notifyClonedEvents(final Collection<? extends Acknowledgable> events) {
        this.proccessEvents(events, AcknowledgablePlugin::notifyCloned, "Notification cloned Acknowledge");
    }

    private void proccessEvents(final Collection<? extends Acknowledgable> events, BiFunction<AcknowledgablePlugin, String, Boolean> processId, String processName){
        if (events.isEmpty())
            return; // This can happen on pipeline shutdown or in some other situations

        events.stream().forEach(event -> {
            final AcknowledgeToken token = event.getAcknowledgeToken();
            if (token != null) {
                final AcknowledgablePlugin plugin = acknowledgeIdMapping.get(token.getPluginId());
                if (plugin != null) {
                    if (!processId.apply(plugin, token.getAcknowledgeId())) {
                        logger.warn( processName + " for plugin: " + plugin.getId() + " was unsuccesful for id: "
                                + token.getAcknowledgeId());
                    }
                } else {
                    logger.warn("Received " + processName + " for unknown plugin: " + token.getPluginId());
                }
            }
        });
    }

    /**
     * Should be called by a plugin on register
     *
     * @param plugin plugin to be registered
     * @return an AcknowledgeTokenGenerator instance
     */
    @Override
    public AcknowledgeTokenFactory registerPlugin(final AcknowledgablePlugin plugin) {
        synchronized (plugin) {
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
