package org.logstash.config.ir.compiler;

/**
 * {@link Dataset} representing an conditional.
 */
public interface SplitDataset extends Dataset {

    /**
     * {@link Dataset} representing the else branch of the conditional.
     * @return Else Branch Dataset
     */
    Dataset right();
}
