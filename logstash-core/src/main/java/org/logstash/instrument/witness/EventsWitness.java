package org.logstash.instrument.witness;

import org.logstash.instrument.metrics.counter.LongCounter;

/**
 * Witness for events.
 */
final public class EventsWitness{

    private LongCounter filtered;
    private LongCounter out;
    private LongCounter in;
    private LongCounter duration;
    private LongCounter queuePushDuration;
    private final Snitch snitch;
    private boolean dirty; //here for passivity with legacy Ruby implementation

    /**
     * Constructor.
     */
    public EventsWitness() {
        filtered = new LongCounter("filtered");
        out = new LongCounter("out");
        in = new LongCounter("in");
        duration = new LongCounter("duration_in_millis");
        queuePushDuration = new LongCounter("queue_push_duration_in_millis");
        snitch = new Snitch(this);
        dirty = false;
    }

    /**
     * Add to the existing duration
     *
     * @param durationToAdd the amount to add to the existing duration.
     */
    public void duration(long durationToAdd) {
        duration.increment(durationToAdd);
        dirty = true;
    }

    /**
     * increment the filtered count by 1
     */
    public void filtered() {
        filtered.increment();
        dirty = true;
    }

    /**
     * increment the filtered count
     *
     * @param count the count to increment by
     */
    public void filtered(long count) {
        filtered.increment(count);
        dirty = true;
    }

    /**
     * Forgets all information related to this witness.
     */
    public void forgetAll() {
        filtered.reset();
        out.reset();
        in.reset();
        duration.reset();
        queuePushDuration.reset();
        dirty = false;
    }


    /**
     * increment the in count by 1
     */
    public void in() {
        in.increment();
        dirty = true;
    }

    /**
     * increment the in count
     *
     * @param count the number to increment by
     */
    public void in(long count) {
        in.increment(count);
        dirty = true;
    }

    /**
     * increment the out count by 1
     */
    public void out() {
        out.increment();
        dirty = true;
    }

    /**
     * increment the count
     *
     * @param count the number by which to increment by
     */
    public void out(long count) {
        out.increment(count);
        dirty = true;
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
     * Add to the existing queue push duration
     *
     * @param durationToAdd the duration to add
     */
    public void queuePushDuration(long durationToAdd) {
        queuePushDuration.increment(durationToAdd);
        dirty = true;
    }

    /**
     * The snitch for the {@link EventsWitness}. Allows to read discrete metrics values.
     */
    public static class Snitch {

        private final EventsWitness witness;

        Snitch(EventsWitness witness) {
            this.witness = witness;
        }

        /**
         * Gets the duration of the events.
         *
         * @return the events duration.
         */
        public long duration() {
            return witness.duration.getValue();
        }

        /**
         * Gets the filtered events count.
         *
         * @return the count of the filtered events.
         */
        public long filtered() {
            return witness.filtered.getValue();

        }

        /**
         * Gets the in events count.
         *
         * @return the count of the events in.
         */
        public long in() {
            return witness.in.getValue();
        }

        /**
         * Gets the out events count.
         *
         * @return the count of the events out.
         */
        public long out() {
            return witness.out.getValue();
        }

        /**
         * Gets the duration of the queue push
         * @return the queue push duration.
         */
        public long queuePushDuration() {
            return witness.queuePushDuration.getValue();
        }

    }
}
