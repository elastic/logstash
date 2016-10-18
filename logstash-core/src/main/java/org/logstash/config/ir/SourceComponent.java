package org.logstash.config.ir;

/**
 * Created by andrewvc on 9/6/16.
 */
public abstract class SourceComponent implements ISourceComponent {
    private final SourceMetadata meta;

    public SourceComponent(SourceMetadata meta) {
        this.meta = meta;
    }

    public SourceMetadata getMeta() {
        return meta;
    }

    public abstract boolean sourceComponentEquals(ISourceComponent sourceComponent);

    public String toString(int indent) {
        return "toString(int indent) should be implemented for " + this.getClass().getName();
    }


}
