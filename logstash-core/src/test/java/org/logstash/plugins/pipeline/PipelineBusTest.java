package org.logstash.plugins.pipeline;

import org.junit.Before;
import org.junit.Test;

import static junit.framework.TestCase.assertTrue;
import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.core.Is.is;

import org.logstash.RubyUtil;
import org.logstash.ext.JrubyEventExtLibrary;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.LongAdder;
import java.util.stream.Stream;

public class PipelineBusTest {
    static String address = "fooAddr";
    static String otherAddress = "fooAddr";
    static Collection<String> addresses = Arrays.asList(address, otherAddress);

    PipelineBus bus;
    TestPipelineInput input;
    TestPipelineOutput output;

    @Before
    public void setup() {
        bus = new PipelineBus();
        input = new TestPipelineInput();
        output = new TestPipelineOutput();
    }

    @Test
    public void subscribeUnsubscribe() throws InterruptedException {
        assertThat(bus.listen(input, address)).isTrue();
        assertThat(bus.addressStates.get(address).getInput()).isSameAs(input);

        bus.unlisten(input, address);

        // Key should have been pruned
        assertThat(bus.addressStates.containsKey(address)).isFalse();
    }

    @Test
    public void senderRegisterUnregister() {
        bus.registerSender(output, addresses);

        assertThat(bus.addressStates.get(address).hasOutput(output)).isTrue();

        bus.unregisterSender(output, addresses);

        // We should have pruned this address
        assertThat(bus.addressStates.containsKey(address)).isFalse();
    }

    @Test
    public void activeSenderPreventsPrune() {
        bus.registerSender(output, addresses);
        bus.listen(input, address);
        bus.unlistenNonblock(input, address);

        assertThat(bus.addressStates.containsKey(address)).isTrue();
        bus.unregisterSender(output, addresses);
        assertThat(bus.addressStates.containsKey(address)).isFalse();
    }


    @Test
    public void activeListenerPreventsPrune() throws InterruptedException {
        bus.registerSender(output, addresses);
        bus.listen(input, address);
        bus.unregisterSender(output, addresses);

        assertThat(bus.addressStates.containsKey(address)).isTrue();
        bus.unlisten(input, address);
        assertThat(bus.addressStates.containsKey(address)).isFalse();
    }

    @Test
    public void registerUnregisterListenerUpdatesOutputs() {
        bus.registerSender(output, addresses);
        bus.listen(input, address);

        ConcurrentHashMap<String, AddressState> outputAddressesToInputs = bus.outputsToAddressStates.get(output);
        assertThat(outputAddressesToInputs.size()).isEqualTo(1);

        bus.unregisterSender(output, addresses);
        assertThat(bus.outputsToAddressStates.get(output)).isNull();

        bus.registerSender(output, addresses);
        assertThat(bus.outputsToAddressStates.get(output).size()).isEqualTo(1);

    }

    @Test
    public void listenUnlistenUpdatesOutputReceivers() throws InterruptedException {
        bus.registerSender(output, addresses);
        bus.listen(input, address);

        final ConcurrentHashMap<String, AddressState> outputAddressesToInputs = bus.outputsToAddressStates.get(output);

        outputAddressesToInputs.get(address).getInput().internalReceive(Stream.of(rubyEvent()));
        assertThat(input.eventCount.longValue()).isEqualTo(1L);

        bus.unlisten(input, address);

        TestPipelineInput newInput = new TestPipelineInput();
        bus.listen(newInput, address);
        outputAddressesToInputs.get(address).getInput().internalReceive(Stream.of(rubyEvent()));

        // The new event went to the new input, not the old one
        assertThat(newInput.eventCount.longValue()).isEqualTo(1L);
        assertThat(input.eventCount.longValue()).isEqualTo(1L);
    }

    @Test
    public void sendingEmptyListToNowhereStillReturns() {
        bus.registerSender(output, Arrays.asList("not_an_address"));
        bus.sendEvents(output, Collections.emptyList(), true);
    }

    @Test
    public void missingInputEventuallySucceeds() throws InterruptedException {
        bus.registerSender(output, addresses);

        // bus.sendEvent should block at this point since there is no attached listener
        // For this test we want to make sure that the background thread has had time to actually block
        // since if we start the input too soon we aren't testing anything
        // The below code attempts to make sure this happens, though it's hard to be deterministic
        // without making sendEvent take weird arguments the non-test code really doesn't need
        CountDownLatch sendLatch = new CountDownLatch(1);
        Thread sendThread = new Thread(() -> {
            sendLatch.countDown();
            bus.sendEvents(output, Collections.singleton(rubyEvent()), true);
        });
        sendThread.start();

        // Try to ensure that the send actually happened. The latch gets us close,
        // the sleep takes us the full way (hopefully)
        sendLatch.await();
        Thread.sleep(1000);

        bus.listen(input, address);

        // This would block if there's an error in the code
        sendThread.join();

        assertThat(input.eventCount.longValue()).isEqualTo(1L);
    }

    @Test
    public void whenInDefaultNonBlockingModeInputsShutdownInstantly() throws InterruptedException {
        // Test confirms the default. If we decide to change the default we should change this test
        assertThat(bus.isBlockOnUnlisten()).isFalse();

        bus.registerSender(output, addresses);
        bus.listen(input, address);

        bus.unlisten(input, address); // This test would block forever if this is not non-block
        bus.unregisterSender(output, addresses);
    }

    @Test
    public void whenInBlockingModeInputsShutdownLast() throws InterruptedException {
        bus.registerSender(output, addresses);
        bus.listen(input, address);

        bus.setBlockOnUnlisten(true);

        Thread unlistenThread = new Thread( () -> {
            try {
                bus.unlisten(input, address);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        });
        unlistenThread.start();

        // This should unblock the listener thread
        bus.unregisterSender(output, addresses);
        unlistenThread.join();

        assertThat(bus.addressStates).isEmpty();
    }


    private JrubyEventExtLibrary.RubyEvent rubyEvent() {
      return JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY);
    }

    static class TestPipelineInput implements PipelineInput {
        public LongAdder eventCount = new LongAdder();

        @Override
        public boolean internalReceive(Stream<JrubyEventExtLibrary.RubyEvent> events) {
            eventCount.add(events.count());
            return true;
        }

        @Override
        public boolean isRunning() {
            return true;
        }
    }

    static class TestPipelineOutput implements PipelineOutput {
    }
}