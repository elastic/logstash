package org.logstash.plugins.pipeline;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyEventExtLibrary;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Stream;

/**
 * This class is essentially the communication bus / central state for the `pipeline` inputs/outputs to talk to each
 * other.
 *
 * This class is threadsafe. Most method locking is coarse grained with `synchronized` since contention for all these methods
 * shouldn't matter
 */
public class PipelineBus {
    final HashMap<String, AddressState> addressStates = new HashMap<>();
    ConcurrentHashMap<PipelineOutput, ConcurrentHashMap<String, AddressState>> outputsToAddressStates = new ConcurrentHashMap<>();

    private static final Logger logger = LogManager.getLogger(PipelineBus.class);

    /**
     * Sends events from the provided output.
     * @param sender The output sending the events.
     * @param events A collection of JRuby events
     * @param ensureDelivery set to true if you want this to retry indefinitely in the event an event send fails
     */
    public void sendEvents(final PipelineOutput sender,
                          final Collection<JrubyEventExtLibrary.RubyEvent> events,
                          final boolean ensureDelivery) {
        final ConcurrentHashMap<String, AddressState> addressesToInputs = outputsToAddressStates.get(sender);

        addressesToInputs.forEach( (address, addressState) -> {
            final Stream<JrubyEventExtLibrary.RubyEvent> clones = events.stream().map(e -> e.rubyClone(RubyUtil.RUBY));

            PipelineInput input = addressState.getInput(); // Save on calls to getInput since it's volatile
            boolean sendWasSuccess = input != null && input.internalReceive(clones);

            // Retry send if the initial one failed
            while (ensureDelivery && !sendWasSuccess) {
                // We need to refresh the input in case the mapping has updated between loops
                String message = String.format("Attempted to send event to '%s' but that address was unavailable. " +
                        "Maybe the destination pipeline is down or stopping? Will Retry.", address);
                logger.warn(message);
                input = addressState.getInput();
                sendWasSuccess = input != null && input.internalReceive(clones);
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    logger.error("Sleep unexpectedly interrupted in bus retry loop", e);
                }
            }
        });
    }

    /**
     * Should be called by an output on register
     * @param output
     * @param addresses
     */
    public synchronized void registerSender(final PipelineOutput output, final Iterable<String> addresses) {
        addresses.forEach((String address) -> {
            final AddressState state = addressStates.computeIfAbsent(address, AddressState::new);
            state.addOutput(output);
        });

        updateOutputReceivers(output);
    }

    /**
     * Should be called by an output on close
     * @param output output that will be unregistered
     * @param addresses collection of addresses this sender was registered with
     */
    public synchronized void unregisterSender(final PipelineOutput output, final Iterable<String> addresses) {
        addresses.forEach(address -> {
            final AddressState state = addressStates.get(address);
            if (state != null) {
                state.removeOutput(output);
                if (state.isEmpty()) addressStates.remove(address);
            }
        });

        outputsToAddressStates.remove(output);
    }

    /**
     * Updates the internal state for this output to reflect the fact that there may be a change
     * in the inputs receiving events from it.
     * @param output
     */
    private synchronized void updateOutputReceivers(final PipelineOutput output) {
        ConcurrentHashMap<String, AddressState> outputAddressToInputMapping =
                outputsToAddressStates.computeIfAbsent(output, o -> new ConcurrentHashMap<>());

        addressStates.forEach( (address, state) -> {
            if (state.hasOutput(output)) outputAddressToInputMapping.put(address, state);
        });
    }

    /**
     * Listens to a given address with the provided listener
     * Only one listener can listen on an address at a time
     * @param address
     * @param input
     * @return true if the listener successfully subscribed
     */
    public synchronized boolean listen(final PipelineInput input, final String address) {
        final AddressState state = addressStates.computeIfAbsent(address, AddressState::new);
        if (state.assignInputIfMissing(input)) {
            state.getOutputs().forEach(this::updateOutputReceivers);
            return true;
        }
        return false;
    }

    /**
     * Stop listing on the given address with the given listener
     * @param address
     * @param input
     */
    public synchronized void unlisten(final PipelineInput input, final String address) {
        final AddressState state = addressStates.get(address);
        if (state != null) {
            state.unassignInput(input);
            if (state.isEmpty()) addressStates.remove(address);
            state.getOutputs().forEach(this::updateOutputReceivers);
        }
    }
}
