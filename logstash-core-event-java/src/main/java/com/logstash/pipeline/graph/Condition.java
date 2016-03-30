package com.logstash.pipeline.graph;

import org.jruby.runtime.builtin.IRubyObject;

/**
 * Created by andrewvc on 2/24/16.
 */
public class Condition {
    public static final Condition elseCondition = new Condition("__ELSE__");

    final String source;

    final static Condition fromSource(String source) {
        if (source.equals(elseCondition.source)) {
            return elseCondition;
        } else {
            return new Condition(source);
        }
    }

    public Condition(String source) {
        this.source = source;
    }

    public String getSource() {
        return source;
    }

    public boolean equals(Condition other) {
        if (this.source == null) {
            if (other.source == null) {
                return true;
            } else {
                return false;
            }
        } else {
            return other.source.equals(this.source);
        }
    }
}
