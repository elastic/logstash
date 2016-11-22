package org.logstash.config.ir;

/**
 * Created by andrewvc on 9/16/16.
 */
public interface SourceComponent {
    boolean sourceComponentEquals(SourceComponent sourceComponent);
    SourceMetadata getMeta();
}
