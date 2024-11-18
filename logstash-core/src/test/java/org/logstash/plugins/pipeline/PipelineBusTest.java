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

import org.junit.Before;
import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyEventExtLibrary;

import java.time.Duration;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.LongAdder;
import java.util.stream.Stream;

@RunWith(Parameterized.class)
public class PipelineBusTest {
    static String address = "fooAddr";
    static String otherAddress = "fooAddr";
    static Collection<String> addresses = Arrays.asList(address, otherAddress);

    @Parameterized.Parameters(name = "{0}")
    public static Collection<Class<? extends PipelineBus.Testable>> data() {
        return Set.of(PipelineBusV1.Testable.class, PipelineBusV2.Testable.class);
    }

    @Parameterized.Parameter
    public Class<PipelineBus.Testable> busClass;

    PipelineBus.Testable bus;
    TestPipelineInput input;
    TestPipelineOutput output;

    @Before
    public void setup() throws ReflectiveOperationException {
        bus = busClass.getDeclaredConstructor().newInstance();
        input = new TestPipelineInput();
        output = new TestPipelineOutput();
    }

    @Test
    public void subscribeUnsubscribe() throws InterruptedException {
        assertThat(bus.listen(input, address)).isTrue();
        assertThat(bus.getAddressState(address)).hasValueSatisfying((addressState -> {
            assertThat(addressState.getInput()).isSameAs(input);
        }));

        bus.unlisten(input, address);

        // Key should have been pruned
        assertThat(bus.getAddressState(address)).isNotPresent();
    }

    @Test
    public void senderRegisterUnregister() {
        bus.registerSender(output, addresses);

        assertThat(bus.getAddressState(address)).hasValueSatisfying((addressState) -> {
            assertThat(addressState.getOutputs()).contains(output);
        });

        bus.unregisterSender(output, addresses);

        // We should have pruned this address
        assertThat(bus.getAddressState(address)).isNotPresent();
    }

    @Test
    public void activeSenderPreventsPrune() throws InterruptedException {
        bus.registerSender(output, addresses);
        bus.listen(input, address);

        assertThat(bus.getAddressState(address)).hasValueSatisfying((addressState -> {
            assertThat(addressState.getInput()).isSameAs(input);
            assertThat(addressState.getOutputs()).contains(output);
        }));

        bus.setBlockOnUnlisten(false);
        bus.unlisten(input, address);

        assertThat(bus.getAddressState(address)).hasValueSatisfying((addressState -> {
            assertThat(addressState.getInput()).isNull();
            assertThat(addressState.getOutputs()).contains(output);
        }));

        bus.unregisterSender(output, addresses);

        assertThat(bus.getAddressState(address)).isNotPresent();
    }

    @Test
    public void multipleSendersPreventPrune() throws InterruptedException {
        // begin with 1:1 single output to input
        bus.registerSender(output, Collections.singleton(address));
        bus.listen(input, address);
        assertThat(bus.getAddressState(address)).hasValueSatisfying((addressState -> {
            assertThat(addressState.getInput()).isSameAs(input);
            assertThat(addressState.getOutputs()).contains(output);
        }));
        bus.sendEvents(output, Collections.singletonList(rubyEvent()), false);
        assertThat(input.eventCount.longValue()).isEqualTo(1L);

        // attach another output2 as a sender
        final TestPipelineOutput output2 = new TestPipelineOutput();
        bus.registerSender(output2, Collections.singleton(address));
        assertThat(bus.getAddressState(address)).hasValueSatisfying((addressState -> {
            assertThat(addressState.getInput()).isSameAs(input);
            assertThat(addressState.getOutputs()).contains(output, output2);
        }));
        bus.sendEvents(output, Collections.singletonList(rubyEvent()), false);
        bus.sendEvents(output2, Collections.singletonList(rubyEvent()), false);
        assertThat(input.eventCount.longValue()).isEqualTo(3L);

        // unlisten with first input, simulating a pipeline restart
        assertThat(bus.isBlockOnUnlisten()).isFalse();
        bus.unlisten(input, address);
        assertThat(bus.getAddressState(address)).hasValueSatisfying((addressState -> {
            assertThat(addressState.getInput()).isNull();
            assertThat(addressState.getOutputs()).contains(output, output2);
        }));

        // unregister one of the two senders, ensuring that the address state remains in-tact
        bus.unregisterSender(output, Collections.singleton(address));
        assertThat(bus.getAddressState(address)).hasValueSatisfying((addressState -> {
            assertThat(addressState.getInput()).isNull();
            assertThat(addressState.getOutputs()).contains(output2);
        }));

        // listen with a new input, emulating the completion of a pipeline restart
        final TestPipelineInput input2 = new TestPipelineInput();
        assertThat(bus.listen(input2, address)).isTrue();
        assertThat(bus.getAddressState(address)).hasValueSatisfying((addressState -> {
            assertThat(addressState.getInput()).isSameAs(input2);
            assertThat(addressState.getOutputs()).contains(output2);
        }));
        bus.sendEvents(output2, Collections.singletonList(rubyEvent()), false);
        assertThat(input2.eventCount.longValue()).isEqualTo(1L);

        // shut down our remaining sender, ensuring address state remains in-tact
        bus.unregisterSender(output2, Collections.singleton(address));
        assertThat(bus.getAddressState(address)).hasValueSatisfying((addressState -> {
            assertThat(addressState.getInput()).isSameAs(input2);
            assertThat(addressState.getOutputs()).isEmpty();
        }));

        // upon unlistening, ensure orphan address state has been cleaned up
        bus.unlisten(input2, address);
        assertThat(bus.getAddressState(address)).isNotPresent();
    }


    @Test
    public void activeListenerPreventsPrune() throws InterruptedException {
        bus.registerSender(output, addresses);
        bus.listen(input, address);
        bus.unregisterSender(output, addresses);

        assertThat(bus.getAddressState(address)).hasValueSatisfying((addressState -> {
            assertThat(addressState.getInput()).isSameAs(input);
            assertThat(addressState.getOutputs()).isEmpty();
        }));

        bus.setBlockOnUnlisten(false);
        bus.unlisten(input, address);

        assertThat(bus.getAddressState(address)).isNotPresent();
    }

    @Test
    public void registerUnregisterListenerUpdatesOutputs() {
        bus.registerSender(output, addresses);
        bus.listen(input, address);

        assertThat(bus.getAddressStates(output)).hasValueSatisfying((addressStates) -> {
            assertThat(addressStates).hasSize(1);
        });

        bus.unregisterSender(output, addresses);
        assertThat(bus.getAddressStates(output)).isNotPresent();
        assertThat(bus.getAddressState(address)).hasValueSatisfying((addressState) -> {
            assertThat(addressState.getInput()).isSameAs(input);
            assertThat(addressState.getOutputs()).isEmpty();
        });

        bus.registerSender(output, addresses);
        assertThat(bus.getAddressStates(output)).hasValueSatisfying((addressStates) -> {
            assertThat(addressStates).hasSize(1);
        });
        assertThat(bus.getAddressState(address)).hasValueSatisfying((addressState) -> {
            assertThat(addressState.getInput()).isSameAs(input);
            assertThat(addressState.getOutputs()).contains(output);
        });
    }

    @Test
    public void listenUnlistenUpdatesOutputReceivers() throws InterruptedException {
        bus.registerSender(output, addresses);
        bus.listen(input, address);

        bus.sendEvents(output, Collections.singletonList(rubyEvent()), false);
        assertThat(input.eventCount.longValue()).isEqualTo(1L);

        bus.unlisten(input, address);

        TestPipelineInput newInput = new TestPipelineInput();
        bus.listen(newInput, address);

        bus.sendEvents(output, Collections.singletonList(rubyEvent()), false);

        // The new event went to the new input, not the old one
        assertThat(newInput.eventCount.longValue()).isEqualTo(1L);
        assertThat(input.eventCount.longValue()).isEqualTo(1L);
    }

    @Test
    public void sendingEmptyListToNowhereStillReturns() {
        bus.registerSender(output, List.of("not_an_address"));
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
        TimeUnit.SECONDS.toMillis(30);
        unlistenThread.join(Duration.ofSeconds(30).toMillis());
        assertThat(unlistenThread.getState()).isEqualTo(Thread.State.TERMINATED);

        assertThat(bus.getAddressState(address)).isNotPresent();
    }

    @Test
    public void blockingShutdownDeadlock() throws InterruptedException {
        final ExecutorService executor = Executors.newFixedThreadPool(10);
        try {
            for (int i = 0; i < 100; i++) {
                bus.registerSender(output, addresses);
                bus.listen(input, address);
                bus.setBlockOnUnlisten(true);

                // we use a CountDownLatch to increase the likelihood
                // of simultaneous execution
                final CountDownLatch startLatch = new CountDownLatch(2);
                final CompletableFuture<Void> unlistenFuture = CompletableFuture.runAsync(asRunnable(() -> {
                    startLatch.countDown();
                    startLatch.await();
                    bus.unlisten(input, address);
                }), executor);
                final CompletableFuture<Void> unregisterFuture = CompletableFuture.runAsync(asRunnable(() -> {
                    startLatch.countDown();
                    startLatch.await();
                    bus.unregisterSender(output, addresses);
                }), executor);

                // ensure that our tasks all exit successfully, quickly
                assertThatCode(() -> CompletableFuture.allOf(unlistenFuture, unregisterFuture).get(1, TimeUnit.SECONDS))
                        .withThreadDumpOnError()
                        .withFailMessage("Expected unlisten and unregisterSender to not deadlock, but they did not return in a reasonable amount of time in the <%s>th iteration", i)
                        .doesNotThrowAnyException();
            }
        } finally {
            executor.shutdownNow();
        }
    }

    @FunctionalInterface
    interface ExceptionalRunnable<E extends Throwable> {
        void run() throws E;
    }

    private Runnable asRunnable(final ExceptionalRunnable<?> exceptionalRunnable) {
        return () -> {
            try {
                exceptionalRunnable.run();
            } catch (Throwable e) {
                throw new RuntimeException(e);
            }
        };
    }


    @Test
    public void whenInputFailsOutputRetryOnlyNotYetDelivered() throws InterruptedException {
        bus.registerSender(output, addresses);
        int expectedReceiveInvocations = 2;
        CountDownLatch sendsCoupleOfCallsLatch = new CountDownLatch(expectedReceiveInvocations);
        int positionOfFailure = 1;
        input = new TestFailPipelineInput(sendsCoupleOfCallsLatch, positionOfFailure);
        bus.listen(input, address);

        final List<JrubyEventExtLibrary.RubyEvent> events = new ArrayList<>();
        events.add(rubyEvent());
        events.add(rubyEvent());
        events.add(rubyEvent());

        CountDownLatch senderThreadStarted = new CountDownLatch(1);
        Thread sendThread = new Thread(() -> {
            senderThreadStarted.countDown();

            // Exercise
            bus.sendEvents(output, events, true);
        });
        sendThread.start();

        senderThreadStarted.await(); // Ensure server thread is started

        // Ensure that send actually happened a couple of times.
        // Send method retry mechanism sleeps 1 second on each retry!
        boolean coupleOfCallsDone = sendsCoupleOfCallsLatch.await(3, TimeUnit.SECONDS);
        sendThread.join();

        // Verify
        assertThat(coupleOfCallsDone).isTrue();
        assertThat(((TestFailPipelineInput)input).getLastBatchSize()).isEqualTo(events.size() - positionOfFailure);
    }

    private JrubyEventExtLibrary.RubyEvent rubyEvent() {
      return JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY);
    }

    static class TestPipelineInput implements PipelineInput {
        public LongAdder eventCount = new LongAdder();

        @Override
        public ReceiveResponse internalReceive(Stream<JrubyEventExtLibrary.RubyEvent> events) {
            eventCount.add(events.count());
            return ReceiveResponse.completed();
        }

        @Override
        public String getId() {
            return "anonymous";
        }

        @Override
        public boolean isRunning() {
            return true;
        }
    }

    static class TestPipelineOutput implements PipelineOutput {
        @Override
        public String getId() {
            return "anonymous";
        }
    }

    static class TestFailPipelineInput extends TestPipelineInput {
        private final CountDownLatch receiveCalls;
        private int receiveInvocationsCount = 0;
        private final int positionOfFailure;
        private int lastBatchSize = 0;

        public TestFailPipelineInput(CountDownLatch failedCallsLatch, int positionOfFailure) {
            this.receiveCalls = failedCallsLatch;
            this.positionOfFailure = positionOfFailure;
        }

        @Override
        public ReceiveResponse internalReceive(Stream<JrubyEventExtLibrary.RubyEvent> events) {
            receiveCalls.countDown();
            if (receiveInvocationsCount == 0) {
                // simulate a fail on first invocation at desired position
                receiveInvocationsCount++;
                return ReceiveResponse.failedAt(positionOfFailure, new Exception("An artificial fail"));
            } else {
                receiveInvocationsCount++;
                lastBatchSize = (int) events.count();

                return ReceiveResponse.completed();
            }
        }

        int getLastBatchSize() {
            return lastBatchSize;
        }
    }
}