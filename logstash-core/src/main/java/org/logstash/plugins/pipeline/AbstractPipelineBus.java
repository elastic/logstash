package org.logstash.plugins.pipeline;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyEventExtLibrary;

import java.util.Arrays;
import java.util.stream.Stream;

public abstract class AbstractPipelineBus implements PipelineBus {

    private static final Logger LOGGER = LogManager.getLogger(AbstractPipelineBus.class);

    protected static void doSendEvents(JrubyEventExtLibrary.RubyEvent[] orderedEvents, AddressState.ReadOnly addressState, boolean ensureDelivery) {
        boolean partialProcessing;
        int lastFailedPosition = 0;
        do {
            Stream<JrubyEventExtLibrary.RubyEvent> clones = Arrays.stream(orderedEvents)
                    .skip(lastFailedPosition)
                    .map(e -> e.rubyClone(RubyUtil.RUBY));

            PipelineInput input = addressState.getInput(); // Save on calls to getInput since it's volatile
            // A missing input is a new unavailable response, not another occurrence of the
            // previous partial failure. Reusing that failure would skip its prefix twice.
            final ReceiveResponse response = input == null ? ReceiveResponse.closing() : input.internalReceive(clones);
            partialProcessing = ensureDelivery && !response.wasSuccess();
            if (partialProcessing) {
                if (response.getStatus() == PipelineInput.ReceiveStatus.FAIL) {
                    // when last call to internalReceive generated a fail for the subset of the orderedEvents
                    // it is handling, restart from the cumulative last-failed position of the batch so that
                    // the next attempt will operate on a subset that excludes those successfully received.
                    lastFailedPosition += response.getSequencePosition();
                    LOGGER.warn("Attempted to send events to '{}' but that address reached error condition with {} events remaining. " +
                            "Will Retry. Root cause {}", addressState.getAddress(), orderedEvents.length - lastFailedPosition, response.getCauseMessage());
                } else {
                    LOGGER.warn("Attempted to send event to '{}' but that address was unavailable. " +
                            "Maybe the destination pipeline is down or stopping? Will Retry.", addressState.getAddress());
                }

                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    LOGGER.error("Sleep unexpectedly interrupted in bus retry loop", e);
                }
            }
        } while (partialProcessing);
    }
}
