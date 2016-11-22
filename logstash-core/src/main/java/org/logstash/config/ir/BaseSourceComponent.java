package org.logstash.config.ir;

/**
 * Created by andrewvc on 9/6/16.
 *
 * This class is useful to inherit from for things that need to be source components
 * since it handles storage of the meta property for you and reduces a lot of boilerplate.
 *
 */
public abstract class BaseSourceComponent implements SourceComponent {
    private final SourceMetadata meta;

    public BaseSourceComponent(SourceMetadata meta) {
        this.meta = meta;
    }

    public SourceMetadata getMeta() {
        return meta;
    }

    public abstract boolean sourceComponentEquals(SourceComponent sourceComponent);

    public String toString(int indent) {
        return "toString(int indent) should be implemented for " + this.getClass().getName();
    }
}
