package org.logstash.config.ir;

/**
 * Created by andrewvc on 9/16/16.
 */
public interface ISourceComponent {
    boolean sourceComponentEquals(ISourceComponent sourceComponent);
    SourceMetadata getMeta();
}
