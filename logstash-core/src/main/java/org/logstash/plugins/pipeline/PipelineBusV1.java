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
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

/**
 * This class is the communication bus for the `pipeline` inputs and outputs to talk to each other.
 * <p>
 * This class is threadsafe.
 */
class PipelineBusV1 extends AbstractPipelineBus implements PipelineBus {

    final ConcurrentHashMap<String, AddressState> addressStates = new ConcurrentHashMap<>();
    final ConcurrentHashMap<PipelineOutput, ConcurrentHashMap<String, AddressState>> outputsToAddressStates = new ConcurrentHashMap<>();
    volatile boolean blockOnUnlisten = false;
    private static final Logger logger = LogManager.getLogger(PipelineBusV1.class);

    @Override
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
                doSendEvents(orderedEvents, addressState.getReadOnlyView(), ensureDelivery);
            });
        }
    }

    /**
     * Should be called by an output on register
     *
     * @param output    output to be registered
     * @param addresses collection of addresses on which to register this sender
     */
    @Override
    public void registerSender(final PipelineOutput output, final Iterable<String> addresses) {
        synchronized (output) {
            addresses.forEach((String address) -> {
                addressStates.compute(address, (k, value) -> {
                    final AddressState state = value != null ? value : new AddressState(address);
                    state.addOutput(output);

                    return state;
                });
            });

            updateOutputReceivers(output);
        }
    }

    @Override
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

    @Override
    public boolean listen(final PipelineInput input, final String address) {
        synchronized (input) {
            final boolean[] result = new boolean[1];

            addressStates.compute(address, (k, value) -> {
                AddressState state = value != null ? value : new AddressState(address);

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

    @Override
    public void unlisten(final PipelineInput input, final String address) throws InterruptedException {
        synchronized (input) {
            if (this.blockOnUnlisten) {
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
    void unlistenBlock(final PipelineInput input, final String address) throws InterruptedException {
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

                final Set<PipelineOutput> outputs = state.getOutputs();
                if (outputs.isEmpty()) {
                    state.unassignInput(input);

                    waiting[0] = false;
                    return null;
                } else {
                    logger.info(() -> String.format("input `%s` is not ready to unlisten from `%s` because the address still has attached senders (%s)", input.getId(), address, outputs.stream().map(PipelineOutput::getId).collect(Collectors.toSet())));
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
    void unlistenNonblock(final PipelineInput input, final String address) {
        addressStates.computeIfPresent(address, (k, state) -> {
            state.unassignInput(input);
            state.getOutputs().forEach(this::updateOutputReceivers);
            return state.isEmpty() ? null : state;
        });
    }

    @Override
    public void setBlockOnUnlisten(boolean blockOnUnlisten) {
        this.blockOnUnlisten = blockOnUnlisten;
    }

    @VisibleForTesting
    static class Testable extends PipelineBusV1 implements PipelineBus.Testable {

        @Override
        @VisibleForTesting
        public boolean isBlockOnUnlisten() {
            return blockOnUnlisten;
        }

        @Override
        @VisibleForTesting
        public Optional<AddressState.ReadOnly> getAddressState(String address) {
            return Optional.ofNullable(addressStates.get(address)).map(AddressState::getReadOnlyView);
        }

        @Override
        @VisibleForTesting
        public Optional<Set<AddressState.ReadOnly>> getAddressStates(PipelineOutput sender) {
            return Optional.ofNullable(outputsToAddressStates.get(sender))
                    .map(ConcurrentHashMap::values)
                    .map(as -> as.stream().map(AddressState::getReadOnlyView).collect(Collectors.toSet()));
        }
    }
}
