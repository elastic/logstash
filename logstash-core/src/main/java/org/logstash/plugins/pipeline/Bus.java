package org.logstash.plugins.pipeline;

import org.logstash.ext.JrubyEventExtLibrary;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;

public class Bus {
    private static ConcurrentHashMap<String,PipelineInput> ADDRESS_TO_INPUT = new ConcurrentHashMap<>();
    private static ConcurrentHashMap<String, ConcurrentHashMap.KeySetView<PipelineOutput,Boolean>>
            ADDRESS_TO_OUTPUT = new ConcurrentHashMap<>();

    static class AddressesByRunState {
        private final List<String> running;
        private final List<String> notRunning;

        AddressesByRunState() {
            this.running = new ArrayList<>();
            this.notRunning = new ArrayList<>();
        }
    }

    static AddressesByRunState addressesByRunState() {
        AddressesByRunState addressesByRunState = new AddressesByRunState();
        ADDRESS_TO_INPUT.forEach( (address, input) -> {
            if (input.isRunning()) {
                addressesByRunState.running.add(address);
            } else {
                addressesByRunState.notRunning.add(address);
            }
        });
        return addressesByRunState;
    }

    static void registerSender(PipelineOutput output, List<String> addresses) {
        addresses.forEach( address -> ADDRESS_TO_OUTPUT.compute(address, (a, outputs) -> {
            if (outputs == null) outputs = ConcurrentHashMap.newKeySet();
            outputs.add(output);
            return outputs;
        }));
    }

    static void unregisterSender(PipelineOutput output, List<String> addresses) {
        addresses.forEach( address -> ADDRESS_TO_OUTPUT.computeIfPresent(address, (a, outputs) -> {
            outputs.remove(address);
            // Return null to delete the key entry and free memory if the list is empty
            return outputs.isEmpty() ? null : outputs;
        }));
    }

    /**
     * Listens to a given address with the provided listener
     * Only one listener can listen on an address at a time
     * @param address
     * @param input
     * @return true if the listener successfully subscribed
     */
    static boolean listen(String address, PipelineInput input) {
        PipelineInput putResult = ADDRESS_TO_INPUT.putIfAbsent(address, input);
        return putResult == null || putResult == input;
    }

    /**
     * Stop listing on the given address with the given listener
     * @param address
     * @param input
     * @return true if the listener successfully unsubscribed
     */
    static boolean unlisten(String address, PipelineInput input) {
        return ADDRESS_TO_INPUT.remove(address, input);
    }

    // Only really used in tests
    static void reset() {
        ADDRESS_TO_INPUT.clear();
    }
}
