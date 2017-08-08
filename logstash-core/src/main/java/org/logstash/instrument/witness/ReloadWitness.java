package org.logstash.instrument.witness;

import org.logstash.Timestamp;
import org.logstash.ext.JrubyTimestampExtLibrary;
import org.logstash.instrument.metrics.counter.LongCounter;
import org.logstash.instrument.metrics.gauge.RubyTimeStampGauge;

/**
 * A witness to record reloads.
 */
final public class ReloadWitness {

    private final LongCounter success;
    private final LongCounter failure;
    private final ErrorWitness lastError;
    private final RubyTimeStampGauge lastSuccessTimestamp;
    private final RubyTimeStampGauge lastFailureTimestamp;
    private final Snitch snitch;

    /**
     * Constructor.
     */
    public ReloadWitness() {
        success = new LongCounter("successes");
        failure = new LongCounter("failures");
        lastError = new ErrorWitness();
        lastSuccessTimestamp = new RubyTimeStampGauge("last_success_timestamp");
        lastFailureTimestamp = new RubyTimeStampGauge("last_failure_timestamp");
        snitch = new Snitch(this);
    }

    /**
     * Obtain a reference to the associated error witness.
     *
     * @return the associated {@link ErrorWitness}
     */
    public ErrorWitness error() {
        return lastError;
    }

    /**
     * Record a single failure
     */
    public void failure() {
        failure.increment();
    }

    /**
     * Record a failure
     *
     * @param count the number of failures
     */
    public void failures(long count) {
        failure.increment(count);
    }

    /**
     * Record a single success
     */
    public void success() {
        success.increment();
    }

    /**
     * Record a success
     *
     * @param count the number of successes
     */
    public void successes(long count) {
        success.increment(count);
    }

    /**
     * Get a reference to associated snitch to get discrete metric values.
     *
     * @return the associate {@link Snitch}
     */
    public Snitch snitch() {
        return snitch;
    }

    /**
     * Set the last success timestamp.
     *
     * @param timestamp the {@link JrubyTimestampExtLibrary.RubyTimestamp} to set
     * @deprecated
     */
    public void lastSuccessTimestamp(JrubyTimestampExtLibrary.RubyTimestamp timestamp) {
        lastSuccessTimestamp.set(timestamp);
    }

    /**
     * Set the last failure timestamp.
     *
     * @param timestamp the {@link JrubyTimestampExtLibrary.RubyTimestamp} to set
     * @deprecated
     */
    public void lastFailureTimestamp(JrubyTimestampExtLibrary.RubyTimestamp timestamp) {
        lastFailureTimestamp.set(timestamp);
    }

    /**
     * The Reload snitch. Provides a means to get discrete metric values.
     */
    public static class Snitch {

        private final ReloadWitness witness;

        Snitch(ReloadWitness witness) {
            this.witness = witness;
        }

        /**
         * Get the number of successful reloads
         *
         * @return the count of successful reloads
         */
        public long successes() {
            return witness.success.getValue();
        }

        /**
         * Get the number of failed reloads
         *
         * @return the count of failed reloads
         */
        public long failures() {
            return witness.failure.getValue();
        }

        /**
         * Gets the timestamp for the last success reload
         *
         * @return {@link Timestamp} of the last successful reload
         * @deprecated
         */
        public Timestamp lastSuccessTimestamp() {
            return witness.lastSuccessTimestamp.getValue();
        }

        /**
         * Gets the timestamp for the last failed reload
         *
         * @return {@link Timestamp} of the last failed reload
         * @deprecated
         */
        public Timestamp lastFailureTimestamp() {
            return witness.lastFailureTimestamp.getValue();
        }

    }
}
