package org.logstash.config.ir;

/**
 * Created by andrewvc on 9/6/16.
 */
public abstract class SourceComponent {
    private final SourceMetadata meta;

    public SourceComponent(SourceMetadata meta) {
        this.meta = meta;
    }

    public SourceMetadata getMeta() {
        return meta;
    }

    public abstract boolean sourceComponentEquals(SourceComponent sourceComponent);

    public String toString(int indent) {
        return "toString(int indent) should be implemented for " + this.getClass().getName();
    }

    @Override
    public String toString() {
        return toString(2);
    }

    public String indentPadding(int length) {
        return new String(new char[length]).replace("\0", " ");
    }
}
