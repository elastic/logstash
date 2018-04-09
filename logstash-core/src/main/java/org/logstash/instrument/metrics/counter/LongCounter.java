package org.logstash.instrument.metrics.counter;

import java.util.concurrent.atomic.LongAdder;
import org.jruby.RubySymbol;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.instrument.metrics.AbstractMetric;
import org.logstash.instrument.metrics.MetricType;

/**
 * A {@link CounterMetric} that is backed by a {@link Long} type.
 */
public class LongCounter extends AbstractMetric<Long> implements CounterMetric<Long> {

    /**
     * Dummy counter used by some functionality as a placeholder when metrics are disabled.
     */
    private static final LongCounter DUMMY_COUNTER = new LongCounter("dummy");

    private static final IllegalArgumentException NEGATIVE_COUNT_EXCEPTION = new IllegalArgumentException("Counters can not be incremented by negative values");
    private LongAdder longAdder;

    /**
     * Extracts the backing LongCounter from a Ruby
     * {@code LogStash::Instrument::MetricType::Counter} for efficient access by Java code.
     * @param metric Ruby {@code Logstash::Instrument::Metric}
     * @param key Identifier of the Counter
     * @return either the backing LongCounter or {@link #DUMMY_COUNTER} in case the input
     * {@code metric} was a Ruby {@code LogStash::Instrument::NullMetric}
     */
    public static LongCounter fromRubyBase(final IRubyObject metric, final RubySymbol key) {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        final IRubyObject counter = metric.callMethod(context, "counter", key);
        counter.callMethod(context, "increment", context.runtime.newFixnum(0));
        final LongCounter javaCounter;
        if (LongCounter.class.isAssignableFrom(counter.getJavaClass())) {
            javaCounter = (LongCounter) counter.toJava(LongCounter.class);
        } else {
            javaCounter = DUMMY_COUNTER;
        }
        return javaCounter;
    }

    /**
     * Constructor
     *
     * @param name The name of this metric. This value may be used for display purposes.
     */
    public LongCounter(String name) {
        super(name);
        longAdder = new LongAdder();
    }

    @Override
    public MetricType getType() {
        return MetricType.COUNTER_LONG;
    }

    @Override
    public Long getValue() {
        return longAdder.longValue();
    }

    @Override
    public void increment() {
        increment(1l);
    }

    @Override
    public void increment(Long by) {
        if (by < 0) {
            throw NEGATIVE_COUNT_EXCEPTION;
        }
        longAdder.add(by);
    }

    /**
     * Optimized version of {@link #increment(Long)} to avoid auto-boxing.
     * @param by The value which to increment by. Can not be negative.
     */
    public void increment(long by) {
        if (by < 0) {
            throw NEGATIVE_COUNT_EXCEPTION;
        }
        longAdder.add(by);
    }

    /**
     * Resets the counter back to it's initial state.
     */
    public void reset(){
        //replacing since LongAdder#reset "is only effective if there are no concurrent updates", we can not make that guarantee
        longAdder = new LongAdder();
    }

}
