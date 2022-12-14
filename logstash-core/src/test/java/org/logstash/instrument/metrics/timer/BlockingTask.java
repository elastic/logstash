package org.logstash.instrument.metrics.timer;

import com.google.common.util.concurrent.Monitor;

import java.time.Duration;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.function.Function;
import java.util.function.Supplier;

/**
 * A {@code BlockingTask} is a test tool for coordinating sequential operations in what
 * is normally asynchronous code. Its {@link Factory} provides methods for spawning tasks
 * that block in an {@code ExecutorService} until they are released by your code.
 * @param <T>
 */
class BlockingTask<T> {

    public static class Factory {
        private final ExecutorService executorService;

        public Factory(final ExecutorService executorService) {
            this.executorService = executorService;
        }

        /**
         * Executes the provided {@code Consumer<ControlChannel>} in the executor service
         * and blocks until control is yielded in the executing thread by sending
         * {@link ControlChannel#markReadyAndBlockUntilRelease}.
         *
         * @param function your task, which <em>MUST</em> send {@link ControlChannel#markReadyAndBlockUntilRelease}.
         * @return a {@code BlockingTask} for you to send {@link BlockingTask#complete()}
         *
         * @param <TT> the return-type of your function, which may be {@code Void}.
         */
        public <TT> BlockingTask<TT> wrapping(final Function<ControlChannel, TT> function) {
            final ControlChannel controlChannel = new ControlChannel();
            final Future<TT> future = executorService.submit(() -> {
                return function.apply(controlChannel);
            });

            controlChannel.blockUntilReady();

            return new BlockingTask<TT>(controlChannel, future);
        }

        /**
         * Spawns a task in the executor and blocks the current thread until the task is running.
         *
         * <p>Your deferred action will be executed <em>after</em> the task is released
         * and <em>before</em> control is returned to the thread that releases it.
         *
         * @param supplier your code, which will be executed in the executor pool when this task is released.
         * @return a {@code BlockingTask} waiting
         *
         * @param <TT> the return-type of your supplier, which may be {@code Void}.
         */
        public <TT> BlockingTask<TT> deferUntilReleased(final Supplier<TT> supplier) {
            return wrapping((controlChannel) -> {
                controlChannel.markReadyAndBlockUntilRelease();
                return supplier.get();
            });
        }
    }

    private final ControlChannel controlChannel;
    private final Future<T> future;

    private static final Duration SAFEGUARD = Duration.ofSeconds(10);

    private BlockingTask(final ControlChannel controlChannel,
                         final Future<T> future) {
        this.controlChannel = controlChannel;
        this.future = future;
    }

    public T complete() throws ExecutionException, InterruptedException, TimeoutException {
        controlChannel.release();
        return future.get(SAFEGUARD.getSeconds(), TimeUnit.SECONDS);
    }

    public static class ControlChannel {
        private volatile boolean isReady = false;
        private volatile boolean isReleased = false;

        private final Monitor monitor = new Monitor();
        private final Monitor.Guard guardReady = monitor.newGuard(() -> isReady);
        private final Monitor.Guard guardRelease = monitor.newGuard(() -> isReleased);

        public void markReadyAndBlockUntilRelease() {
            try {
                monitor.enterInterruptibly(10, TimeUnit.SECONDS);
                this.isReady = true;
                monitor.waitFor(guardRelease, SAFEGUARD);
                monitor.leave();
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            }
        }

        private void blockUntilReady() {
            try {
                monitor.enterWhen(guardReady, SAFEGUARD);
                monitor.leave();
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            }
        }

        private void release() {
            try {
                monitor.enterInterruptibly(SAFEGUARD);
                isReleased = true;
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            } finally {
                monitor.leave();
            }
        }
    }
}
