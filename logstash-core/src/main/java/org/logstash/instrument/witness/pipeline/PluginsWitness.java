package org.logstash.instrument.witness.pipeline;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import org.logstash.instrument.witness.SerializableWitness;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * A Witness for the set of plugins.
 */
@JsonSerialize(using = PluginsWitness.Serializer.class)
public class PluginsWitness implements SerializableWitness {

    private final Map<String, PluginWitness> inputs;
    private final Map<String, PluginWitness> outputs;
    private final Map<String, PluginWitness> filters;
    private final Map<String, PluginWitness> codecs;
    private static final String KEY = "plugins";

    /**
     * Constructor.
     */
    public PluginsWitness() {
        this.inputs = new ConcurrentHashMap<>();
        this.outputs = new ConcurrentHashMap<>();
        this.filters = new ConcurrentHashMap<>();
        this.codecs = new ConcurrentHashMap<>();
    }

    /**
     * Gets the {@link PluginWitness} for the given id, creates the associated {@link PluginWitness} if needed
     *
     * @param id the id of the input
     * @return the associated {@link PluginWitness} (for method chaining)
     */
    public PluginWitness inputs(String id) {
        return getPlugin(inputs, id);
    }

    /**
     * Gets the {@link PluginWitness} for the given id, creates the associated {@link PluginWitness} if needed
     *
     * @param id the id of the output
     * @return the associated {@link PluginWitness} (for method chaining)
     */
    public PluginWitness outputs(String id) {
        return getPlugin(outputs, id);
    }

    /**
     * Gets the {@link PluginWitness} for the given id, creates the associated {@link PluginWitness} if needed
     *
     * @param id the id of the filter
     * @return the associated {@link PluginWitness} (for method chaining)
     */
    public PluginWitness filters(String id) {
        return getPlugin(filters, id);
    }

    /**
     * Gets the {@link PluginWitness} for the given id, creates the associated {@link PluginWitness} if needed
     *
     * @param id the id of the codec
     * @return the associated {@link PluginWitness} (for method chaining)
     */
    public PluginWitness codecs(String id) {
        return getPlugin(codecs, id);
    }

    /**
     * Forgets all information related to the the plugins.
     */
    public void forgetAll() {
        inputs.clear();
        outputs.clear();
        filters.clear();
        codecs.clear();
    }

    /**
     * Gets or creates the {@link PluginWitness}
     *
     * @param plugin the map of the plugin type.
     * @param id     the id of the plugin
     * @return existing or new {@link PluginWitness}
     */
    private static PluginWitness getPlugin(Map<String, PluginWitness> plugin, String id) {
        return plugin.computeIfAbsent(id, PluginWitness::new);
    }

    @Override
    public void genJson(JsonGenerator gen, SerializerProvider provider) throws IOException {
        PluginsWitness.Serializer.innerSerialize(this, gen, provider);
    }

    /**
     * The Jackson serializer.
     */
    public static final class Serializer extends StdSerializer<PluginsWitness> {

        private static final long serialVersionUID = 1L;

        /**
         * Default constructor - required for Jackson
         */
        public Serializer() {
            this(PluginsWitness.class);
        }

        /**
         * Constructor
         *
         * @param t the type to serialize
         */
        private Serializer(Class<PluginsWitness> t) {
            super(t);
        }

        @Override
        public void serialize(PluginsWitness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            gen.writeStartObject();
            innerSerialize(witness, gen, provider);
            gen.writeEndObject();
        }

        static void innerSerialize(PluginsWitness witness, JsonGenerator gen,
            SerializerProvider provider) throws IOException {
            gen.writeObjectFieldStart(KEY);

            serializePlugins("inputs", witness.inputs, gen, provider);
            serializePlugins("filters", witness.filters, gen, provider);
            serializePlugins("outputs", witness.outputs, gen, provider);
            //codec is not serialized

            gen.writeEndObject();
        }

        private static void serializePlugins(String key, Map<String, PluginWitness> plugin,
            JsonGenerator gen, SerializerProvider provider) throws IOException {
            gen.writeArrayFieldStart(key);
            for (Map.Entry<String, PluginWitness> entry : plugin.entrySet()) {
                gen.writeStartObject();
                entry.getValue().genJson(gen, provider);
                gen.writeEndObject();
            }
            gen.writeEndArray();

        }
    }
}
