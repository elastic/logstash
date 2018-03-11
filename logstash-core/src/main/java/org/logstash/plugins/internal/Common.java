package org.logstash.plugins.internal;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

public class Common {
    public static class AddressState {
        private final String address;
        private final Set<InternalOutput> outputs = ConcurrentHashMap.newKeySet();
        private volatile InternalInput input = null;

        private AddressState(String address) {
            this.address = address;
            this.input = input;
        }

        public Set<InternalOutput> getOutputs() {
            return outputs;
        }

        public InternalInput getInput() {
            return input;
        }
    }

    public static ConcurrentHashMap<String, AddressState> ADDRESS_STATES = new ConcurrentHashMap<>();

    static class AddressesByRunState {
        private final List<String> running;
        private final List<String> notRunning;

        AddressesByRunState() {
            this.running = new ArrayList<>();
            this.notRunning = new ArrayList<>();
        }

        public List<String> getRunning() {
            return running;
        }

        public List<String> getNotRunning() {
            return notRunning;
        }
    }

    static AddressesByRunState addressesByRunState() {
        AddressesByRunState addressesByRunState = new AddressesByRunState();
        ADDRESS_STATES.forEach( (address, state) -> {
            if (state.input != null && state.input.isRunning()) {
                addressesByRunState.running.add(address);
            } else {
                addressesByRunState.notRunning.add(address);
            }
        });
        return addressesByRunState;
    }

    public static void registerSender(Collection<String> addresses, InternalOutput output) {
        addresses.forEach( address -> ADDRESS_STATES.compute(address, (a, state) -> {
            if (state == null) {
                state = new AddressState(address);
            }
            state.outputs.add(output);
            if (state.input != null) {
                output.updateAddressReceiver(address, state.input::internalReceive);
            }
            return state;
        }));
    }

    public static void special(Collection<String> addresses, InternalOutput output) {
        addresses.forEach( address -> {
            ADDRESS_STATES.compute(address, (a, state) -> {
                state.outputs.remove(output);
                return state;
            });
            output.removeAddressReceiver(address);
        });
    }

    /**
     * Listens to a given address with the provided listener
     * Only one listener can listen on an address at a time
     * @param address
     * @param input
     * @return true if the listener successfully subscribed
     */
    static boolean listen(final String address, final InternalInput input) {
        final boolean[] subscribed = new boolean[]{false};
        ADDRESS_STATES.compute(address, (a, state) -> {
            if (state == null) state = new AddressState(address);
            // We can't subscribe if another listener is active
            if (state.input == null) {
                subscribed[0] = true;
                state.input = input;
                state.outputs.forEach(o -> o.updateAddressReceiver(address, input::internalReceive));
            }
            return state;
        });
        return subscribed[0];
    }

    /**
     * Stop listing on the given address with the given listener
     * @param address
     * @param input
     * @return true if the listener successfully unsubscribed
     */
    static boolean unlisten(final String address, final InternalInput input) {
        final boolean[] unsubscribed = new boolean[]{true};
        ADDRESS_STATES.computeIfPresent(address, (a, state) -> {
            if (state.input == input) {
                state.input = null;
            } else {
                unsubscribed[0] = false;
            }
            return state;
        });
        return unsubscribed[0];
    }

    // Only really used in tests
    static void reset() {
        ADDRESS_STATES.clear();
    }
}
