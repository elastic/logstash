package org.logstash.instrument.metrics.timer;

import com.google.common.util.concurrent.Monitor;
import org.junit.Test;
import org.logstash.instrument.metrics.ManualAdvanceClock;

import java.time.Duration;
import java.util.Objects;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;


import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.is;
import static org.junit.Assert.assertThat;

/**
 * This {@code TimerMetricTest} is meant to be inherited by tests covering the implementations of {@link TimerMetric},
 * and includes baseline tests for guaranteeing that the value of the metric includes the duration of
 * execution before control is given back to the caller.
 *
 * <p>At an <em>interface</em>-level, we make no guarantees that tracked executions will be committed into the
 * value <em>until</em> control is returned, which means that the value may or may not include "uncommitted" or
 * currently-executing tracked timings. This means that our assertions can only apply when there are no concurrent
 * executions happening.
 */
public abstract class TimerMetricTest {

    abstract ManualAdvanceClock getClock();
    abstract TimerMetric getTimerMetric();

    @Test
    public void testBaselineFunctionality() {
        final ManualAdvanceClock manualAdvanceClock = getClock();
        final TimerMetric timerMetric = getTimerMetric();

        assertThat(timerMetric.getValue(), is(equalTo(0L)));

        // nothing executing, no advance
        manualAdvanceClock.advance(Duration.ofSeconds(30));
        assertThat(timerMetric.getValue(), is(equalTo(0L)));

        // single execution, advances whole millis
        timerMetric.time(() -> {
            manualAdvanceClock.advance(Duration.ofNanos(1234567890L));
        });
        assertThat(timerMetric.getValue(), is(equalTo(1234L)));

        // nothing executing, no advance
        manualAdvanceClock.advance(Duration.ofSeconds(30));
        assertThat(timerMetric.getValue(), is(equalTo(1234L)));

        // untracked execution, advances as expected
        timerMetric.reportUntrackedMillis(7326L);
        assertThat(timerMetric.getValue(), is(equalTo(8560L)));
    }

    @Test
    public void testValueAfterConcurrentTrackedExecutions() throws Exception {
        final ManualAdvanceClock manualAdvanceClock = getClock();
        final TimerMetric timerMetric = getTimerMetric();
        final ExecutorService executor = Executors.newFixedThreadPool(5);

        // assert baseline timer is not incrementing when time is passing
        assertThat(timerMetric.getValue(), is(equalTo(0L)));
        manualAdvanceClock.advance(Duration.ofMillis(10_000_000_000L));
        assertThat(timerMetric.getValue(), is(equalTo(0L)));

        // methodology note: each state-change affects a single column in a decimal-formatted long,
        // which gives us a bread-crumb for identifying he cause of issues when our expectation
        // does not match
        long expectedAdvance = 0L;

        final TimedBlockingTask taskOne = TimedBlockingTask.start(executor, timerMetric);
        manualAdvanceClock.advance(Duration.ofMillis(1L));
        expectedAdvance += Math.multiplyExact(1L, 1);

        final TimedBlockingTask taskTwo = TimedBlockingTask.start(executor, timerMetric);
        manualAdvanceClock.advance(Duration.ofMillis(10L));
        expectedAdvance += Math.multiplyExact(10L, 2);

        taskOne.complete();
        manualAdvanceClock.advance(Duration.ofMillis(100L));
        expectedAdvance += Math.multiplyExact(100L, 1);

        final TimedBlockingTask taskThree = TimedBlockingTask.start(executor, timerMetric);
        manualAdvanceClock.advance(Duration.ofMillis(1_000L));
        expectedAdvance += Math.multiplyExact(1_000L, 2);

        final TimedBlockingTask taskFour = TimedBlockingTask.start(executor, timerMetric);
        manualAdvanceClock.advance(Duration.ofMillis(10_000L));
        expectedAdvance += Math.multiplyExact(10_000L, 3);

        taskThree.complete();
        manualAdvanceClock.advance(Duration.ofMillis(100_000L));
        expectedAdvance += Math.multiplyExact(100_000L, 2);

        taskTwo.complete();
        manualAdvanceClock.advance(Duration.ofMillis(1_000_000L));
        expectedAdvance += Math.multiplyExact(1_000_000L, 1);

        taskFour.complete();
        manualAdvanceClock.advance(Duration.ofMillis(10_000_000L));
        expectedAdvance += Math.multiplyExact(10_000_000L, 0);

        final TimedBlockingTask taskFive = TimedBlockingTask.start(executor, timerMetric);
        manualAdvanceClock.advance(Duration.ofMillis(100_000_000L));
        expectedAdvance += Math.multiplyExact(100_000_000L, 1);

        taskFive.complete();
        manualAdvanceClock.advance(Duration.ofMillis(1_000_000_000L));
        expectedAdvance += Math.multiplyExact(1_000_000_000L, 0);

        // note: we assert both
        assertThat(timerMetric.getValue(), is(equalTo(101_232_121L)));
        assertThat(timerMetric.getValue(), is(equalTo(expectedAdvance)));
    }

    private static class TimedBlockingTask {
        private volatile boolean shouldBlock = true;
        private volatile boolean isBlocking = false;
        private final Monitor monitor = new Monitor();
        private final Monitor.Guard blockRelease = monitor.newGuard(() -> !shouldBlock);
        private final Monitor.Guard blockActive = monitor.newGuard(() -> isBlocking);

        protected volatile Future<?> future;

        private static final Duration SAFEGUARD = Duration.ofSeconds(10);

        static TimedBlockingTask start(final ExecutorService executorService, final TimerMetric timerMetric) {
            final TimedBlockingTask timedBlockingTask = new TimedBlockingTask();
            timedBlockingTask.future = executorService.submit(() -> timerMetric.time(timedBlockingTask::block));
            timedBlockingTask.waitUntilBlocked();
            return timedBlockingTask;
        }

        void block() {
            try {
                monitor.enterInterruptibly(10, TimeUnit.SECONDS);
                this.isBlocking = true;
                monitor.waitFor(blockRelease, SAFEGUARD);
                this.isBlocking = false;
                monitor.leave();
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            }
        }

        void waitUntilBlocked() {
            try {
                monitor.enterWhen(blockActive, SAFEGUARD);
                monitor.leave();
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            }
        }

        void complete() throws ExecutionException, InterruptedException, TimeoutException {
            Objects.requireNonNull(this.future);
            try {
                monitor.enterInterruptibly(SAFEGUARD);
                this.shouldBlock = false;
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            } finally {
                monitor.leave();
            }
            this.future.get(SAFEGUARD.getSeconds(), TimeUnit.SECONDS);
        }
    }
}
