package org.logstash.plugins.pipeline;

import com.google.common.annotations.VisibleForTesting;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.ext.JrubyEventExtLibrary;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Consumer;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

class PipelineBusV2 extends AbstractPipelineBus implements PipelineBus {

    // The canonical source of truth for mapping addresses to their AddressStates
    protected final AddressStateMapping addressStates = new AddressStateMapping();

    // A cached mapping from any given registered sender (PipelineOutput) to a query-only view of
    // the AddressState-s to which it is registered.
    protected final Map<PipelineOutput, Set<AddressState.ReadOnly>> addressStatesBySender = new ConcurrentHashMap<>();

    // effectively a set-on-shutdown flag
    protected volatile boolean blockOnUnlisten = false;

    private static final Logger LOGGER = LogManager.getLogger(PipelineBusV2.class);

    @Override
    public void sendEvents(final PipelineOutput sender,
                           final Collection<JrubyEventExtLibrary.RubyEvent> events,
                           final boolean ensureDelivery) {
        if (events.isEmpty()) return;

        final Set<AddressState.ReadOnly> addressStates = addressStatesBySender.get(sender);
        if (addressStates == null) {
            throw new IllegalStateException("cannot send events from unregistered sender");
        }

        // In case of retry on the same set events, a stable order is needed, else
        // the risk is to reprocess twice some events. Collection can't guarantee order stability.
        JrubyEventExtLibrary.RubyEvent[] orderedEvents = events.toArray(new JrubyEventExtLibrary.RubyEvent[0]);

        addressStates.forEach(addressState -> doSendEvents(orderedEvents, addressState, ensureDelivery));
    }

    @Override
    public void registerSender(final PipelineOutput sender,
                               final Iterable<String> addresses) {
        Objects.requireNonNull(sender, "sender must not be null");
        Objects.requireNonNull(addresses, "addresses must not be null");
        addressStatesBySender.compute(sender, (po, existing) -> {
            return StreamSupport.stream(addresses.spliterator(), false)
                                .map((addr) -> addressStates.mutate(addr, (as) -> as.addOutput(po)))
                                .collect(Collectors.toUnmodifiableSet());
        });
    }

    @Override
    public void unregisterSender(final PipelineOutput sender,
                                 final Iterable<String> addresses) {
        Objects.requireNonNull(sender, "sender must not be null");
        Objects.requireNonNull(addresses, "addresses must not be null");
        addressStatesBySender.compute(sender, (po, existing) -> {
            addresses.forEach((addr) -> addressStates.mutate(addr, (as) -> as.removeOutput(po)));
            return null;
        });
    }

    @Override
    public boolean listen(final PipelineInput listener,
                          final String address) {
        Objects.requireNonNull(listener, "listener must not be null");
        Objects.requireNonNull(address, "address must not be null");
        final AddressState.ReadOnly result = addressStates.mutate(address, (addressState) -> {
            addressState.assignInputIfMissing(listener);
        });
        return (result != null && result.getInput() == listener);
    }

    @Override
    public void unlisten(final PipelineInput listener,
                         final String address) throws InterruptedException {
        Objects.requireNonNull(listener, "listener must not be null");
        Objects.requireNonNull(address, "address must not be null");
        if (this.blockOnUnlisten) {
            unlistenBlocking(listener, address);
        } else {
            unlistenNonblock(listener, address);
        }
    }

    private void unlistenNonblock(final PipelineInput listener,
                                   final String address) {
        addressStates.mutate(address, (addressState) -> addressState.unassignInput(listener));
    }

    private void unlistenBlocking(final PipelineInput listener,
                          final String address) throws InterruptedException {
        synchronized (Objects.requireNonNull(listener, "listener must not be null")) {
            while(!tryUnlistenOrphan(listener, address)) {
                listener.wait(10000);
            }
        }
    }

    /**
     * Makes a singular attempt to unlisten to the address that succeeds if and only if
     * there are no senders registered to the address
     * @param listener the {@link PipelineInput} that to unlisten
     * @param address the address from which to unlisten
     * @return true iff this listener is not listening after the attempt
     */
    private boolean tryUnlistenOrphan(final PipelineInput listener,
                                      final String address) {
        final AddressState.ReadOnly result = addressStates.mutate(address, (addressState) -> {
            final Set<PipelineOutput> outputs = addressState.getOutputs();
            if (outputs.isEmpty()) {
                addressState.unassignInput(listener);
            } else {
                LOGGER.trace(() -> String.format("input `%s` is not ready to unlisten from `%s` because the address still has attached senders (%s)", listener.getId(), address, outputs.stream().map(PipelineOutput::getId).collect(Collectors.toSet())));
            }
        });
        return result == null || result.getInput() != listener;
    }

    @Override
    public void setBlockOnUnlisten(final boolean blockOnUnlisten) {
        this.blockOnUnlisten = blockOnUnlisten;
    }

    protected static class AddressStateMapping {

        private final Map<String, AddressState> mapping = new ConcurrentHashMap<>();

        public AddressState.ReadOnly mutate(final String address,
                                            final Consumer<AddressState> consumer) {
            final AddressState result = mapping.compute(address, (a, addressState) -> {
                if (addressState == null) {
                    addressState = new AddressState(address);
                }

                consumer.accept(addressState);

                // If this addressState has a listener, ensure that any waiting
                // threads get notified so that they can resume immediately
                final PipelineInput currentInput = addressState.getInput();
                if (currentInput != null) {
                    synchronized (currentInput) { currentInput.notifyAll(); }
                }

                return addressState.isEmpty() ? null : addressState;
            });
            return result == null ? null : result.getReadOnlyView();
        }

        private AddressState.ReadOnly get(final String address) {
            final AddressState result = mapping.get(address);
            return result == null ? null : result.getReadOnlyView();
        }
    }

    @VisibleForTesting
    static class Testable extends PipelineBusV2 implements PipelineBus.Testable {

        @Override
        @VisibleForTesting
        public boolean isBlockOnUnlisten() {
            return this.blockOnUnlisten;
        }

        @Override
        @VisibleForTesting
        public Optional<AddressState.ReadOnly> getAddressState(final String address) {
            return Optional.ofNullable(addressStates.get(address));
        }

        @Override
        @VisibleForTesting
        public Optional<Set<AddressState.ReadOnly>> getAddressStates(final PipelineOutput sender) {
            return Optional.ofNullable(addressStatesBySender.get(sender));
        }

    }
}
