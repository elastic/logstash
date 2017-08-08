package org.logstash.instrument.witness;

/**
 * A single pipeline witness.
 */
final public class PipelineWitness {

    private final ReloadWitness reloadWitness;
    private final EventsWitness eventsWitness;
    private final ConfigWitness configWitness;
    private final PluginsWitness pluginsWitness;
    private final QueueWitness queueWitness;

    /**
     * Constructor.
     *
     * @param pipelineName The uniquely identifying name of the pipeline.
     */
    public PipelineWitness(String pipelineName) {  //NOTE - pipeline name is used as part of the serialization
        this.reloadWitness = new ReloadWitness();
        this.eventsWitness = new EventsWitness();
        this.configWitness = new ConfigWitness();
        this.pluginsWitness = new PluginsWitness();
        this.queueWitness = new QueueWitness();
    }

    /**
     * Get a reference to associated config witness
     *
     * @return the associated {@link ConfigWitness}
     */
    public ConfigWitness config() {
        return configWitness;
    }

    /**
     * Get a reference to associated events witness
     *
     * @return the associated {@link EventsWitness}
     */
    public EventsWitness events() {
        return eventsWitness;
    }

    /**
     * Gets the {@link PluginWitness} for the given id, creates the associated {@link PluginWitness} if needed
     * @param id the id of the filter
     * @return the associated {@link PluginWitness} (for method chaining)
     */
    public PluginWitness filters(String id) {
        return pluginsWitness.filters(id);
    }

    /**
     * Forgets all events for this witness.
     */
    public void forgetEvents() {
        events().forgetAll();
    }

    /**
     * Forgets all plugins for this witness.
     */
    public void forgetPlugins() {
        plugins().forgetAll();
    }

    /**
     * Gets the {@link PluginWitness} for the given id, creates the associated {@link PluginWitness} if needed
     * @param id the id of the input
     * @return the associated {@link PluginWitness} (for method chaining)
     */
    public PluginWitness inputs(String id) {
        return pluginsWitness.inputs(id);
    }

    /**
     * Gets the {@link PluginWitness} for the given id, creates the associated {@link PluginWitness} if needed
     * @param id the id of the output
     * @return the associated {@link PluginWitness} (for method chaining)
     */
    public PluginWitness outputs(String id) {
        return pluginsWitness.outputs(id);
    }

    /**
     * Get a reference to associated plugins witness
     *
     * @return the associated {@link PluginsWitness}
     */
    public PluginsWitness plugins() {
        return pluginsWitness;
    }

    /**
     * Get a reference to associated reload witness
     *
     * @return the associated {@link ReloadWitness}
     */
    public ReloadWitness reloads() {
        return reloadWitness;
    }

    /**
     * Get a reference to associated queue witness
     *
     * @return the associated {@link QueueWitness}
     */
    public QueueWitness queue() {
        return queueWitness;
    }
}

