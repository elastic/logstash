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
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyEventExtLibrary;

import java.util.Arrays;
import java.util.Collection;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Stream;

/**
 * This class is the communication bus for the `pipeline` inputs and outputs to talk to each other.
 * <p>
 * This class is threadsafe.
 */
public class PipelineBus {

    final ConcurrentHashMap<String, AddressState> addressStates = new ConcurrentHashMap<>();
    final ConcurrentHashMap<PipelineOutput, ConcurrentHashMap<String, AddressState>> outputsToAddressStates = new ConcurrentHashMap<>();
    volatile boolean blockOnUnlisten = false;
    private static final Logger logger = LogManager.getLogger(PipelineBus.class);

    /**
     * Sends events from the provided output.
     *
     * @param sender         The output sending the events.
     * @param events         A collection of JRuby events
     * @param ensureDelivery set to true if you want this to retry indefinitely in the event an event send fails
     */
    public void sendEvents(final PipelineOutput sender,
                           final Collection<JrubyEventExtLibrary.RubyEvent> events,
                           final boolean ensureDelivery) {
        if (events.isEmpty()) return; // This can happen on pipeline shutdown or in some other situations

        synchronized (sender) {
            final ConcurrentHashMap<String, AddressState> addressesToInputs = outputsToAddressStates.get(sender);
            // In case of retry on the same set events, a stable order is needed, else
            // the risk is to reprocess twice some events. Collection can't guarantee order stability.
            JrubyEventExtLibrary.RubyEvent[] orderedEvents = events.toArray(new JrubyEventExtLibrary.RubyEvent[0]);

            addressesToInputs.forEach((address, addressState) -> {
                boolean sendWasSuccess = false;
                ReceiveResponse lastResponse = null;
                boolean partialProcessing;
                int lastFailedPosition = 0;
                do {
                    Stream<JrubyEventExtLibrary.RubyEvent> clones = Arrays.stream(orderedEvents)
                            .skip(lastFailedPosition)
                            .map(e -> e.rubyClone(RubyUtil.RUBY));

                    PipelineInput input = addressState.getInput(); // Save on calls to getInput since it's volatile
                    if (input != null) {
                        lastResponse = input.internalReceive(clones);
                        sendWasSuccess = lastResponse.wasSuccess();
                    }
                    partialProcessing = ensureDelivery && !sendWasSuccess;
                    if (partialProcessing) {
                        if (lastResponse != null && lastResponse.getStatus() == PipelineInput.ReceiveStatus.FAIL) {
                            // when last call to internalReceive generated a fail for the subset of the orderedEvents
                            // it is handling, restart from the cumulative last-failed position of the batch so that
                            // the next attempt will operate on a subset that excludes those successfully received.
                            lastFailedPosition += lastResponse.getSequencePosition();
                            logger.warn("Attempted to send events to '{}' but that address reached error condition with {} events remaining. " +
                                    "Will Retry. Root cause {}", address, orderedEvents.length - lastFailedPosition, lastResponse.getCauseMessage());
                        } else {
                            logger.warn("Attempted to send event to '{}' but that address was unavailable. " +
                                    "Maybe the destination pipeline is down or stopping? Will Retry.", address);
                        }

                        try {
                            Thread.sleep(1000);
                        } catch (InterruptedException e) {
                            Thread.currentThread().interrupt();
                            logger.error("Sleep unexpectedly interrupted in bus retry loop", e);
                        }
                    }
                } while (partialProcessing);
            });
        }
    }

    /**
     * Should be called by an output on register
     *
     * @param output    output to be registered
     * @param addresses collection of addresses on which to register this sender
     */
    public void registerSender(final PipelineOutput output, final Iterable<String> addresses) {
        synchronized (output) {
            addresses.forEach((String address) -> {
                addressStates.compute(address, (k, value) -> {
                    final AddressState state = value != null ? value : new AddressState();
                    state.addOutput(output);

                    return state;
                });
            });

            updateOutputReceivers(output);
        }
    }

    /**
     * Should be called by an output on close
     *
     * @param output    output that will be unregistered
     * @param addresses collection of addresses this sender was registered with
     */
    public void unregisterSender(final PipelineOutput output, final Iterable<String> addresses) {
        synchronized (output) {
            addresses.forEach(address -> {
                addressStates.computeIfPresent(address, (k, state) -> {
                    state.removeOutput(output);

                    if (state.isEmpty()) return null;

                    return state;
                });
            });

            outputsToAddressStates.remove(output);
        }
    }

    /**
     * Updates the internal state for this output to reflect the fact that there may be a change
     * in the inputs receiving events from it.
     *
     * @param output output to update
     */
    private void updateOutputReceivers(final PipelineOutput output) {
        outputsToAddressStates.compute(output, (k, value) -> {
            ConcurrentHashMap<String, AddressState> outputAddressToInputMapping = value != null ? value : new ConcurrentHashMap<>();

            addressStates.forEach((address, state) -> {
                if (state.hasOutput(output)) outputAddressToInputMapping.put(address, state);
            });

            return outputAddressToInputMapping;
        });
    }

    /**
     * Listens to a given address with the provided listener
     * Only one listener can listen on an address at a time
     *
     * @param input   Input to register as listener
     * @param address Address on which to listen
     * @return true if the listener successfully subscribed
     */
    public boolean listen(final PipelineInput input, final String address) {
        synchronized (input) {
            final boolean[] result = new boolean[1];

            addressStates.compute(address, (k, value) -> {
                AddressState state = value != null ? value : new AddressState();

                if (state.assignInputIfMissing(input)) {
                    state.getOutputs().forEach(this::updateOutputReceivers);
                    result[0] = true;
                } else {
                    result[0] = false;
                }

                return state;
            });

            return result[0];
        }
    }

    /**
     * Stop listening on the given address with the given listener
     * Will change behavior depending on whether {@link #isBlockOnUnlisten()} is true or not.
     * Will call a blocking method if it is, a non-blocking one if it isn't
     *
     * @param input   Input that should stop listening
     * @param address Address on which the input should stop listening
     * @throws InterruptedException if interrupted while attempting to stop listening
     */
    public void unlisten(final PipelineInput input, final String address) throws InterruptedException {
        synchronized (input) {
            if (isBlockOnUnlisten()) {
                unlistenBlock(input, address);
            } else {
                unlistenNonblock(input, address);
            }
        }
    }

    /**
     * Stop listening on the given address with the given listener. Blocks until upstream outputs have
     * stopped.
     *
     * @param input   Input that should stop listening
     * @param address Address on which to stop listening
     * @throws InterruptedException if interrupted while attempting to stop listening
     */
    private void unlistenBlock(final PipelineInput input, final String address) throws InterruptedException {
        final boolean[] waiting = {true};

        // Block until all senders are done
        // Outputs shutdown before their connected inputs
        while (true) {
            addressStates.compute(address, (k, state) -> {
                // If this happens the pipeline was asked to shutdown
                // twice, so there's no work to do
                if (state == null) {
                    waiting[0] = false;
                    return null;
                }

                if (state.getOutputs().isEmpty()) {
                    state.unassignInput(input);

                    waiting[0] = false;
                    return null;
                }

                return state;
            });

            if (!waiting[0]) {
                break;
            } else {
                Thread.sleep(100);
            }
        }
    }

    /**
     * Unlisten to use during reloads. This lets upstream outputs block while this input is missing
     *
     * @param input   Input that should stop listening
     * @param address Address on which to stop listening
     */
    @VisibleForTesting
    void unlistenNonblock(final PipelineInput input, final String address) {
        addressStates.computeIfPresent(address, (k, state) -> {
            state.unassignInput(input);
            state.getOutputs().forEach(this::updateOutputReceivers);
            return state.isEmpty() ? null : state;
        });
    }

    @VisibleForTesting
    boolean isBlockOnUnlisten() {
        return blockOnUnlisten;
    }

    public void setBlockOnUnlisten(boolean blockOnUnlisten) {
        this.blockOnUnlisten = blockOnUnlisten;
    }
}
