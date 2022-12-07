package org.logstash.instrument.metrics.timer;

import org.junit.Test;
import org.logstash.instrument.metrics.ManualAdvanceClock;
import org.logstash.instrument.metrics.MetricType;

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
 * This {@code TimerMetricTest} is meant to be inherited by tests covering the
 * implementations of {@link TimerMetric}, and includes baseline tests for guaranteeing
 * that the value of the metric includes the duration of execution before control is
 * given back to the caller.
 *
 * <p>At an <em>interface</em>-level, we only guarantee that tracked executions will
 * be committed into the value <em>before</em> control is returned to the caller, which
 * means that the value may or may not include "uncommitted" or mid-execution
 * tracked timings. As a result, these shared tests can only validate the cumulative
 * value when there are zero currently-tracked executions in-flight. Implementations
 * that report live-tracking will need to validate mid-execution behaviour on their
 * own.</p>
 */
public abstract class TimerMetricTest {

    protected final ManualAdvanceClock manualAdvanceClock = new ManualAdvanceClock(Instant.now());
    protected final TestTimerMetricFactory testTimerMetricFactory = new TestTimerMetricFactory(manualAdvanceClock);

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
        sharedTestWithConcurrentTrackedExecutions(false);
    }

    /**
     * This shared test optionally validates the value of the timer metric after
     * each state change, enabling additional validations for live timers.
     *
     * @param validateLiveTracking whether to validate the value of the timer after each clock change.
     * @throws Exception
     */
    void sharedTestWithConcurrentTrackedExecutions(final boolean validateLiveTracking) throws Exception {
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
        if (validateLiveTracking) { assertThat(timerMetric.getValue(), is(equalTo(expectedAdvance))); }

        final BlockingTask<Void> taskTwo = timedBlockingTask(timerMetric);
        manualAdvanceClock.advance(Duration.ofMillis(10L));
        expectedAdvance += Math.multiplyExact(10L, 2);
        if (validateLiveTracking) { assertThat(timerMetric.getValue(), is(equalTo(expectedAdvance))); }

        taskOne.complete();
        manualAdvanceClock.advance(Duration.ofMillis(100L));
        expectedAdvance += Math.multiplyExact(100L, 1);
        if (validateLiveTracking) { assertThat(timerMetric.getValue(), is(equalTo(expectedAdvance))); }

        final BlockingTask<Void> taskThree = timedBlockingTask(timerMetric);
        manualAdvanceClock.advance(Duration.ofMillis(1_000L));
        expectedAdvance += Math.multiplyExact(1_000L, 2);
        if (validateLiveTracking) { assertThat(timerMetric.getValue(), is(equalTo(expectedAdvance))); }

        final BlockingTask<Void> taskFour = timedBlockingTask(timerMetric);
        manualAdvanceClock.advance(Duration.ofMillis(10_000L));
        expectedAdvance += Math.multiplyExact(10_000L, 3);
        if (validateLiveTracking) { assertThat(timerMetric.getValue(), is(equalTo(expectedAdvance))); }

        taskThree.complete();
        manualAdvanceClock.advance(Duration.ofMillis(100_000L));
        expectedAdvance += Math.multiplyExact(100_000L, 2);
        if (validateLiveTracking) { assertThat(timerMetric.getValue(), is(equalTo(expectedAdvance))); }

        taskTwo.complete();
        manualAdvanceClock.advance(Duration.ofMillis(1_000_000L));
        expectedAdvance += Math.multiplyExact(1_000_000L, 1);
        if (validateLiveTracking) { assertThat(timerMetric.getValue(), is(equalTo(expectedAdvance))); }

        taskFour.complete();
        manualAdvanceClock.advance(Duration.ofMillis(10_000_000L));
        expectedAdvance += Math.multiplyExact(10_000_000L, 0);
        if (validateLiveTracking) { assertThat(timerMetric.getValue(), is(equalTo(expectedAdvance))); }

        final BlockingTask<Void> taskFive = timedBlockingTask(timerMetric);
        manualAdvanceClock.advance(Duration.ofMillis(100_000_000L));
        expectedAdvance += Math.multiplyExact(100_000_000L, 1);
        if (validateLiveTracking) { assertThat(timerMetric.getValue(), is(equalTo(expectedAdvance))); }

        taskFive.complete();
        manualAdvanceClock.advance(Duration.ofMillis(1_000_000_000L));
        expectedAdvance += Math.multiplyExact(1_000_000_000L, 0);
        if (validateLiveTracking) { assertThat(timerMetric.getValue(), is(equalTo(expectedAdvance))); }

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

    @Test
    public void testName() {
        final TimerMetric timerMetric = initTimerMetric("testing-timer-metric");
        assertThat(timerMetric.getName(), equalTo("testing-timer-metric"));
    }

    @Test
    public void testType() {
        final TimerMetric timerMetric = initTimerMetric("testing-timer-metric-2");
        assertThat(timerMetric.getType(), equalTo(MetricType.TIMER_LONG));
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

    @Test
    public void testAccumulatesExcessNanos() {
        final TimerMetric timerMetric = initTimerMetric("precisely");

        for (int i = 0; i < 1000; i++) {
            timerMetric.time(() -> manualAdvanceClock.advance(Duration.ofNanos(999_999L)));
        }

        assertThat(timerMetric.getValue(), is(equalTo(999L)));
    }

    private BlockingTask<Void> timedBlockingTask(final TimerMetric timerMetric) {
        return blockingTaskFactory.wrapping((controlChannel) -> {
            timerMetric.time(controlChannel::markReadyAndBlockUntilRelease);
            return null;
        });
    }
}
