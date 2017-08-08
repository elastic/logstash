package org.logstash.instrument.witness;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * A Witness for the set of plugins.
 */
public class PluginsWitness{

    private final Map<String, PluginWitness> inputs;
    private final Map<String, PluginWitness> outputs;
    private final Map<String, PluginWitness> filters;

    /**
     * Constructor.
     */
    public PluginsWitness() {

        this.inputs = new ConcurrentHashMap<>();
        this.outputs = new ConcurrentHashMap<>();
        this.filters = new ConcurrentHashMap<>();
     }

    /**
     * Gets the {@link PluginWitness} for the given id, creates the associated {@link PluginWitness} if needed
     * @param id the id of the input
     * @return the associated {@link PluginWitness} (for method chaining)
     */
    public PluginWitness inputs(String id) {
        return getPlugin(inputs, id);
    }

    /**
     * Gets the {@link PluginWitness} for the given id, creates the associated {@link PluginWitness} if needed
     * @param id the id of the output
     * @return the associated {@link PluginWitness} (for method chaining)
     */
    public PluginWitness outputs(String id) {
        return getPlugin(outputs, id);
    }

    /**
     * Gets the {@link PluginWitness} for the given id, creates the associated {@link PluginWitness} if needed
     * @param id the id of the filter
     * @return the associated {@link PluginWitness} (for method chaining)
     */
    public PluginWitness filters(String id) {
        return getPlugin(filters, id);
    }

    /**
     * Forgets all information related to the the plugins.
     */
    public void forgetAll() {
        inputs.clear();
        outputs.clear();
        filters.clear();
    }

    /**
     * Gets or creates the {@link PluginWitness}
     *
     * @param plugin the map of the plugin type.
     * @param id     the id of the plugin
     * @return existing or new {@link PluginWitness}
     */
    private PluginWitness getPlugin(Map<String, PluginWitness> plugin, String id) {
        return plugin.computeIfAbsent(id, k -> new PluginWitness(k) );
    }

}

