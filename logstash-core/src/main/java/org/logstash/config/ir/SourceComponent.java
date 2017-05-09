package org.logstash.config.ir;

import org.logstash.common.SourceWithMetadata;

/**
 * Created by andrewvc on 9/16/16.
 */
public interface SourceComponent {
    boolean sourceComponentEquals(SourceComponent sourceComponent);
    SourceWithMetadata getSourceWithMetadata();
}
