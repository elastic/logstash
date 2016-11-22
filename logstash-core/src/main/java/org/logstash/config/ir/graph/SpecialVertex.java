package org.logstash.config.ir.graph;

import org.logstash.config.ir.ISourceComponent;

/**
 * Created by andrewvc on 9/15/16.
 */
public class SpecialVertex extends Vertex {
    private final Type type;

    public SpecialVertex() {
        super(null);
        this.type = Type.QUEUE;
    }

    public SpecialVertex(Type type) {
        super(null);
        this.type = type;

    }

    public enum Type {
        FILTER_OUT ("FILTER_OUT"),
        QUEUE ("QUEUE");

        private final String name;

        Type(String s) {
            this.name = s;
        }

        public String toString() {
            return this.name;
        }
    }

    public String toString() {
        return "S[" + this.type + "]";
    }

    @Override
    public boolean sourceComponentEquals(ISourceComponent other) {
        if (other == null) return false;
        if (other == this) return true;
        if (other instanceof SpecialVertex) {
            SpecialVertex otherV = (SpecialVertex) other;
            return otherV.type.equals(this.type);
        }
        return false;
    }
}
