package org.logstash.instrument.metrics.timer;

import org.junit.Test;
import org.logstash.instrument.metrics.ManualAdvanceClock;

import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.is;
import static org.junit.Assert.assertSame;
import static org.junit.Assert.assertThat;
import static org.junit.Assert.fail;

/**
 * This {@code TimerMetricTest} is meant to be inherited by tests covering the implementations of {@link TimerMetric},
 * and includes baseline tests for guaranteeing that the value of the metric includes the duration of
 * execution before control is given back to the caller.
 *
 * <p>At an <em>interface</em>-level, we make no guarantees that tracked executions will be committed into the
 * value <em>until</em> control is returned, which means that the value may or may not include "uncommitted" or
 * currently-executing tracked timings. As a result, our assertions can only place upper-bounds on tracked time
 * when there are no concurrent executions happening.
 */
public abstract class TimerMetricTest {

    protected final ManualAdvanceClock manualAdvanceClock = new ManualAdvanceClock(Instant.now());
    protected final TimerMetricFactory timerMetricFactory = new TimerMetricFactory(manualAdvanceClock);

    private final ExecutorService executorService = Executors.newFixedThreadPool(5);
    private final BlockingTask.Factory blockingTaskFactory = new BlockingTask.Factory(executorService);

    abstract TimerMetric initTimerMetric(String name);

    @Test
    public void testBaselineFunctionality() {
        final TimerMetric timerMetric = initTimerMetric("duration_in_millis");

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
        final TimerMetric timerMetric = initTimerMetric("duration_in_millis");

        // assert baseline timer is not incrementing when time is passing
        assertThat(timerMetric.getValue(), is(equalTo(0L)));
        manualAdvanceClock.advance(Duration.ofMillis(10_000_000_000L));
        assertThat(timerMetric.getValue(), is(equalTo(0L)));

        // methodology note: each state-change affects a single column in a decimal-formatted long,
        // which gives us a bread-crumb for identifying the cause of issues when our expectation
        // does not match
        long expectedAdvance = 0L;

        final BlockingTask<Void> taskOne = timedBlockingTask(timerMetric);
        manualAdvanceClock.advance(Duration.ofMillis(1L));
        expectedAdvance += Math.multiplyExact(1L, 1);

        final BlockingTask<Void> taskTwo = timedBlockingTask(timerMetric);
        manualAdvanceClock.advance(Duration.ofMillis(10L));
        expectedAdvance += Math.multiplyExact(10L, 2);

        taskOne.complete();
        manualAdvanceClock.advance(Duration.ofMillis(100L));
        expectedAdvance += Math.multiplyExact(100L, 1);

        final BlockingTask<Void> taskThree = timedBlockingTask(timerMetric);
        manualAdvanceClock.advance(Duration.ofMillis(1_000L));
        expectedAdvance += Math.multiplyExact(1_000L, 2);

        final BlockingTask<Void> taskFour = timedBlockingTask(timerMetric);
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

        final BlockingTask<Void> taskFive = timedBlockingTask(timerMetric);
        manualAdvanceClock.advance(Duration.ofMillis(100_000_000L));
        expectedAdvance += Math.multiplyExact(100_000_000L, 1);

        taskFive.complete();
        manualAdvanceClock.advance(Duration.ofMillis(1_000_000_000L));
        expectedAdvance += Math.multiplyExact(1_000_000_000L, 0);

        // note: we assert both
        assertThat(timerMetric.getValue(), is(equalTo(101_232_121L)));
        assertThat(timerMetric.getValue(), is(equalTo(expectedAdvance)));
    }

    @Test
    public void testReturnValue() {
        final TimerMetric timerMetric = initTimerMetric("ok");

        final Optional<String> original = Optional.of("hello");

        final Optional<String> result = timerMetric.time(() -> original);

        assertSame(original, result);
    }

    private static class ACheckedException extends Exception {
        private static final long serialVersionUID = 1L;
        public ACheckedException(String message) {
            super(message);
        }
    }

    @Test
    public void testThrowing() {
        final TimerMetric timerMetric = initTimerMetric("oh no");
        final ACheckedException checkedException = new ACheckedException("gotcha");
        try {
            timerMetric.time(() -> { throw checkedException; });
        } catch (ACheckedException chk) {
            assertSame(checkedException, chk);
            return;
        }
        fail("Checked exception not caught!");
    }


    private BlockingTask<Void> timedBlockingTask(final TimerMetric timerMetric) {
        return blockingTaskFactory.wrapping((controlChannel) -> {
            timerMetric.time(controlChannel::markReadyAndBlockUntilRelease);
            return null;
        });
    }
}
