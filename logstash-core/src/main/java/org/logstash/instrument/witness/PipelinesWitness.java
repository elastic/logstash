package org.logstash.instrument.witness;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Witness for the set of pipelines.
 */
final public class PipelinesWitness {

    private final Map<String, PipelineWitness> pipelines;

    /**
     * Constructor.
     */
    public PipelinesWitness() {
        this.pipelines = new ConcurrentHashMap<>();
    }

    /**
     * Get a uniquely named pipeline witness. If one does not exist, it will be created.
     *
     * @param name The name of the pipeline.
     * @return the {@link PipelineWitness} identified by the given name.
     */
    public PipelineWitness pipeline(String name) {
        return pipelines.computeIfAbsent(name, k -> new PipelineWitness(k));
    }

}
