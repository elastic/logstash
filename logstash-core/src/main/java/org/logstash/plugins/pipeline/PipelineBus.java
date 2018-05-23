package org.logstash.plugins.pipeline;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyEventExtLibrary;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.stream.Stream;

/**
 * This class is essentially the communication bus / central state for the `pipeline` inputs/outputs to talk to each
 * other.
 *
 * This class is threadsafe.
 */
public class PipelineBus {
    final HashMap<String, AddressState> addressStates = new HashMap<>();
    final ConcurrentHashMap<PipelineOutput, ConcurrentHashMap<String, AddressState>> outputsToAddressStates = new ConcurrentHashMap<>();
    volatile boolean blockOnUnlisten = false;
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
        if (events.isEmpty()) return; // This can happen on pipeline shutdown or in some other situations

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
    public void registerSender(final PipelineOutput output, final Iterable<String> addresses) {
        addresses.forEach((String address) -> {
            addressStates.compute(address, (k, value) -> {
               final AddressState state = value != null ? value : new AddressState(address);
               state.addOutput(output);

               return state;
            });
        });

        updateOutputReceivers(output);
    }

    /**
     * Should be called by an output on close
     * @param output output that will be unregistered
     * @param addresses collection of addresses this sender was registered with
     */
    public void unregisterSender(final PipelineOutput output, final Iterable<String> addresses) {
        addresses.forEach(address -> {
            addressStates.computeIfPresent(address, (k, state) -> {
                state.removeOutput(output);

                if (state.isEmpty()) return null;

                return state;
            });
        });

        outputsToAddressStates.remove(output);
    }

    /**
     * Updates the internal state for this output to reflect the fact that there may be a change
     * in the inputs receiving events from it.
     * @param output
     */
    private void updateOutputReceivers(final PipelineOutput output) {
        outputsToAddressStates.compute(output, (k, value) -> {
            ConcurrentHashMap<String, AddressState> outputAddressToInputMapping = value != null ? value : new ConcurrentHashMap<>();

            addressStates.forEach( (address, state) -> {
                if (state.hasOutput(output)) outputAddressToInputMapping.put(address, state);
            });

            return outputAddressToInputMapping;
        });
    }

    /**
     * Listens to a given address with the provided listener
     * Only one listener can listen on an address at a time
     * @param address
     * @param input
     * @return true if the listener successfully subscribed
     */
    public boolean listen(final PipelineInput input, final String address) {
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

    /**
     * Stop listening on the given address with the given listener
     * Will change behavior depending on whether {@link #isBlockOnUnlisten()} is true or not.
     * Will call a blocking method if it is, a non-blocking one if it isn't
     * @param input
     * @param address
     */
    public void unlisten(final PipelineInput input, final String address) throws InterruptedException {
        if (isBlockOnUnlisten()) {
            unlistenBlock(input, address);
        } else {
            unlistenNonblock(input, address);
        }
    }

    /**
     * Stop listing on the given address with the given listener
     * @param address
     * @param input
     */
    public void unlistenBlock(final PipelineInput input, final String address) throws InterruptedException {
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

            if (waiting[0] == false) {
                break;
            } else {
                Thread.sleep(100);
            }
        }
    }

    /**
     * Unlisten to use during reloads. This lets upstream outputs block while this input is missing
     * @param input
     * @param address
     */
    public void unlistenNonblock(final PipelineInput input, final String address) {
        addressStates.computeIfPresent(address, (k, state) -> {
           state.unassignInput(input);
           state.getOutputs().forEach(this::updateOutputReceivers);
           return state.isEmpty() ? null : state;
        });
    }

    public boolean isBlockOnUnlisten() {
        return blockOnUnlisten;
    }

    public void setBlockOnUnlisten(boolean blockOnUnlisten) {
        this.blockOnUnlisten = blockOnUnlisten;
    }


}
