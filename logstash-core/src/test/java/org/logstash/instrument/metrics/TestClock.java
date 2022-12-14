package org.logstash.instrument.metrics;

import java.time.Clock;

public abstract class TestClock extends Clock {
    abstract public long nanoTime();
}
