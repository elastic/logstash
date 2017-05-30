package org.logstash.config.ir.imperative;

import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.BaseSourceComponent;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.graph.Graph;

/**
 * Created by andrewvc on 9/6/16.
 */
public abstract class Statement extends BaseSourceComponent {
    public Statement(SourceWithMetadata meta) {
        super(meta);
    }

    public abstract Graph toGraph() throws InvalidIRException;

    public String toString() {
        return toString(2);
    }

    public abstract String toString(int indent);

    public static String indentPadding(int length) {
        return String.format("%" + length + "s", "");
    }
}
