package org.logstash.instrument.metrics.timer;

import co.elastic.logstash.api.TimerMetric;

import java.util.Objects;
import java.util.function.Supplier;
import java.util.stream.Stream;

public class CombinedMillisTimer implements TimerMetric {
    private final TimerMetric[] wrappedTimerMetrics;

    public static TimerMetric combine(final TimerMetric left, final TimerMetric right) {
        System.err.format("%s::combine(%s, %s)\n", CombinedMillisTimer.class.getName(), left, right);
        if (Objects.isNull(left) || Objects.equals(left, ExecutionMillisTimer.nullTimer())) { return Objects.requireNonNullElseGet(right, ExecutionMillisTimer::nullTimer); }
        if (Objects.isNull(right) || Objects.equals(right, ExecutionMillisTimer.nullTimer())) { return Objects.requireNonNullElseGet(left, ExecutionMillisTimer::nullTimer); }

        return new CombinedMillisTimer(new TimerMetric[]{left, right});
    }

    private CombinedMillisTimer(TimerMetric[] wrappedTimerMetrics) {
        this.wrappedTimerMetrics = wrappedTimerMetrics;
    }

    @Override
    public <R> R time(Supplier<R> supplier) {
        final Committer committer = begin();
        try {
            return supplier.get();
        } finally {
            committer.commit();
        }
    }

    @Override
    public Committer begin() {
        final Committer[] committers = Stream.of(this.wrappedTimerMetrics).map(TimerMetric::begin).toArray(Committer[]::new);
        return new CombinedCommitter(committers);
    }

    @Override
    public void reportUntracked(long millisecondsElapsed) {
        Stream.of(wrappedTimerMetrics)
                .forEach(timer -> timer.reportUntracked(millisecondsElapsed));
    }

    private class CombinedCommitter implements Committer {
        private final Committer[] committers;
        public CombinedCommitter(final Committer[] committers) {
            this.committers = committers;
        }

        @Override
        public long commit() {
            return Stream.of(committers)
                    .map(Committer::commit)
                    .reduce(Math::max)
                    .orElse(0L);
        }
    }
}
