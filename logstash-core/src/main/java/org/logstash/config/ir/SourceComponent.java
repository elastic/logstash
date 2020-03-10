package org.logstash.config.ir;

import org.logstash.common.SourceWithMetadata;

public interface SourceComponent {
    boolean sourceComponentEquals(SourceComponent sourceComponent);
    SourceWithMetadata getSourceWithMetadata();
}
