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

import java.util.Collection;

/**
 * This class is the communication bus for acknowledgements at pipeline ends.
 * Implementations should be threadsafe.
 */
public interface AcknowledgeBus {

    /**
     * Acknowledges events if it contains acknowledge token.
     * Should be called at the end of a pipeline
     *
     * @param events A collection of Acknowledgable
     */
    void acknowledgeEvents(final Collection<? extends Acknowledgable> events);


    /**
     * Notify clone of events if it contains acknowledge token
     * when that means an acknowledgeToken can reach end of pipeline
     * multiple times. Like in the case of inter-pipeline communication.
     *
     * @param events A collection of Acknowledgable
     */
    void notifyClonedEvents(final Collection<? extends Acknowledgable> events);

    /**
     * Should be called by a plugin on register
     *
     * @param plugin    plugin to be registered
     * @return an AcknowledgeTokenGenerator instance
     */
    AcknowledgeTokenFactory registerPlugin(final AcknowledgablePlugin plugin);

    /**
     * Should be called by an plugin on close
     *
     * @param plugin    output that will be unregistered
     * @return false if plugin wasn't registered otherwise true
     */
    boolean unregisterPlugin(final AcknowledgablePlugin plugin);

}
