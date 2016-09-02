package org.logstash.config.ir.graph;

/**
 * Created by andrewvc on 9/15/16.
 */
public class SpecialVertex extends Vertex {
    private final Type type;

    public SpecialVertex() {
        this.type = Type.QUEUE;
    }

    public SpecialVertex(Type type) {
        this.type = type;

    }

    enum Type {
        FILTER_IN ("FILTER_IN"),
        FILTER_OUT ("FILTER OUT"),
        OUTPUT_IN ("OUTPUT IN"),
        OUTPUT_OUT ("OUTPUT OUT"),
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
}
