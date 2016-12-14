package org.logstash.config.ir.graph;

import org.logstash.config.ir.ISourceComponent;

/**
 * Created by andrewvc on 9/15/16.
 */
public class SpecialVertex extends Vertex {
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

    private final Type type;
    private final String id;

    public SpecialVertex(Type type) {
        super(null);
        this.id = "special-" + type.toString();
        this.type = type;

    }

    @Override
    public String getId() {
        // There can only be one of each special vertex!
        return id;
    }

    @Override
    public String individualHashSource() {
        return this.getClass().getCanonicalName() + "|" + this.type;
    }

    public Type getType() {
        return type;
    }


    public String toString() {
        return "S[" + this.type + "]";
    }

    @Override
    public SpecialVertex copy() {
        return new SpecialVertex(this.type);
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
