package org.logstash.instrument.witness;

import org.logstash.instrument.metrics.gauge.TextGauge;

/**
 * Witness for a single plugin.
 */
public class PluginWitness {

    private final EventsWitness eventsWitness;
    private final TextGauge id;
    private final TextGauge name;
    private final Snitch snitch;

    /**
     * Constructor.
     *
     * @param id The unique identifier for this plugin.
     */
    public PluginWitness(String id) {
        eventsWitness = new EventsWitness();
        this.id = new TextGauge("id", id);
        this.name = new TextGauge("name");
        this.snitch = new Snitch(this);
    }

    /**
     * Get a reference to the associated events witness.
     *
     * @return the associated {@link EventsWitness}
     */
    public EventsWitness events() {
        return eventsWitness;
    }

    /**
     * Sets the name of this plugin.
     *
     * @param name the name of this plugin.
     * @return an instance of this witness (to allow method chaining)
     */
    public PluginWitness name(String name) {
        this.name.set(name);
        return this;
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
     * Snitch for a plugin. Provides discrete metric values.
     */
    public static class Snitch {

        private final PluginWitness witness;

        Snitch(PluginWitness witness) {
            this.witness = witness;
        }

        /**
         * Gets the id for this plugin.
         *
         * @return the id
         */
        public String id() {
            return witness.id.getValue();
        }

        /**
         * Gets the name of this plugin
         *
         * @return the name
         */
        public String name() {
            return witness.name.getValue();
        }

    }
}
