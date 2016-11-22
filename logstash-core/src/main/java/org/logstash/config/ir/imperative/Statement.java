package org.logstash.config.ir.imperative;

import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.BaseSourceComponent;
import org.logstash.config.ir.SourceMetadata;
import org.logstash.config.ir.graph.Graph;

/**
 * Created by andrewvc on 9/6/16.
 */
public abstract class Statement extends BaseSourceComponent {
    public Statement(SourceMetadata meta) {
        super(meta);
    }

    public abstract Graph toGraph() throws InvalidIRException;

    public String toString() {
        return toString(2);
    }

    public abstract String toString(int indent);

    public String indentPadding(int length) {
        return String.format("%" + length + "s", "");
    }
}
