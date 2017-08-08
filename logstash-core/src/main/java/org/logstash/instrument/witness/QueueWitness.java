package org.logstash.instrument.witness;

import org.logstash.instrument.metrics.gauge.TextGauge;

/**
 * Witness for the queue.
 */
final public class QueueWitness {

    private final TextGauge type;
    private final Snitch snitch;

    /**
     * Constructor.
     */
    public QueueWitness() {
        type = new TextGauge("type");
        snitch = new Snitch(this);
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
     * Sets the type of the queue.
     *
     * @param type The type of the queue.
     */
    public void type(String type) {
        this.type.set(type);
    }

    /**
     * Snitch for queue. Provides discrete metric values.
     */
    public static class Snitch {

        private final QueueWitness witness;

        Snitch(QueueWitness witness) {
            this.witness = witness;
        }

        /**
         * Gets the type of queue
         *
         * @return the queue type.
         */
        public String type() {
            return witness.type.getValue();
        }

    }
}
