package org.logstash.plugins.pipeline;

import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Class for representing the state of an internal address.
 */
public class AddressState {
    private final String address;
    private final Set<PipelineOutput> outputs = ConcurrentHashMap.newKeySet();
    private volatile PipelineInput input = null;

    AddressState(String address) {
        this.address = address;
    }

    /**
     * Add the given output and ensure associated input's receivers are updated
     * @param output
     * @return
     */
    public boolean addOutput(PipelineOutput output) {
        return outputs.add(output);
    }

    public boolean removeOutput(PipelineOutput output) {
        return outputs.remove(output);
    }

    public PipelineInput getInput() {
        return input;
    }

    /**
     * Assigns an input to listen on this address. Will return false if another input is already listening.
     * @param newInput
     * @return true if successful, false if another input is listening
     */
    public synchronized boolean assignInputIfMissing(PipelineInput newInput) {
        if (input == null) {
            input = newInput;
            return true;
        } else if (input == newInput) {
            return true; // We aren't changing anything
        }

        return false;
    }

    /**
     * Unsubscribes the given input from this address
     * @param unsubscribingInput
     * @return true if this input was listening, false otherwise
     */
    public synchronized boolean unassignInput(PipelineInput unsubscribingInput) {
        if (input != unsubscribingInput) return false;

        input = null;
        return true;
    }

    public boolean isRunning() {
        return input != null && input.isRunning();
    }

    public boolean isEmpty() {
        return (input == null) && outputs.isEmpty();
    }

    // Just for tests
    boolean hasOutput(PipelineOutput output) {
        return outputs.contains(output);
    }

    public Set<PipelineOutput> getOutputs() {
        return outputs;
    }
}
