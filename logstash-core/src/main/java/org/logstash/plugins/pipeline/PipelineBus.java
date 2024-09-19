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

package org.logstash.plugins.pipeline;

import com.google.common.annotations.VisibleForTesting;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.ext.JrubyEventExtLibrary;

import java.util.Collection;
import java.util.Optional;
import java.util.Set;

/**
 * A {@code PipelineBus} is the communication bus that allows {@link PipelineOutput}s to
 * send events to {@link PipelineInput}s.
 *
 * @implSpec implementations must be threadsafe for all operations.
 */
public interface PipelineBus {

    Logger LOGGER = LogManager.getLogger(PipelineBus.class);

    /**
     * API-stable entry-point for creating a {@link PipelineBus}
     * @return a new pipeline bus
     */
    static PipelineBus create() {
        final String pipelineBusImplementation = System.getProperty("logstash.pipelinebus.implementation", "v2");
        switch (pipelineBusImplementation) {
            case "v1": return new PipelineBusV1();
            case "v2": return new PipelineBusV2();
            default:
                LOGGER.warn("unknown pipeline-bus implementation: {}", pipelineBusImplementation);
                return new PipelineBusV1();
        }
    }

    /**
     * Sends events from the provided output.
     *
     * @param sender         The output sending the events.
     * @param events         A collection of JRuby events
     * @param ensureDelivery set to true if you want this to retry indefinitely in the event an event send fails
     */
    void sendEvents(PipelineOutput sender,
                    Collection<JrubyEventExtLibrary.RubyEvent> events,
                    boolean ensureDelivery);

    /**
     * Should be called by an output on register
     *
     * @param output    output to be registered
     * @param addresses collection of addresses on which to register this sender
     */
    void registerSender(PipelineOutput output, Iterable<String> addresses);

    /**
     * Should be called by an output on close
     *
     * @param output    output that will be unregistered
     * @param addresses collection of addresses this sender was registered with
     */
    void unregisterSender(PipelineOutput output, Iterable<String> addresses);

    /**
     * Listens to a given address with the provided listener
     * Only one listener can listen on an address at a time
     *
     * @param input   Input to register as listener
     * @param address Address on which to listen
     * @return true if the listener successfully subscribed
     */
    boolean listen(PipelineInput input, String address);

    /**
     * Stop listening on the given address with the given listener
     * Will change behavior depending on whether {@link #setBlockOnUnlisten(boolean)} is true or not.
     * Will call a blocking method if it is, a non-blocking one if it isn't
     *
     * @param input   Input that should stop listening
     * @param address Address on which the input should stop listening
     * @throws InterruptedException if interrupted while attempting to stop listening
     */
    void unlisten(PipelineInput input, String address) throws InterruptedException;

    /**
     * Configure behaviour of {@link #unlisten(PipelineInput, String)} to be blocking,
     * which allows a DAG to shut down senders-first
     *
     * @param blockOnUnlisten true iff future invocations of {@link #unlisten} should block
     */
    void setBlockOnUnlisten(boolean blockOnUnlisten);

    /**
     * This package-private sub-interface allows implementations to provide testable
     * hooks without exposing them publicly
     */
    @VisibleForTesting
    interface Testable extends PipelineBus {
        @VisibleForTesting Optional<AddressState.ReadOnly> getAddressState(final String address);
        @VisibleForTesting Optional<Set<AddressState.ReadOnly>> getAddressStates(final PipelineOutput sender);
        @VisibleForTesting boolean isBlockOnUnlisten();
    }
}
