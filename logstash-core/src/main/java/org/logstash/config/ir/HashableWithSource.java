package org.logstash.config.ir;

import org.logstash.common.Util;

public interface HashableWithSource extends Hashable {
    @Override
    default String uniqueHash() {
        return Util.digest(hashSource());
    }
    String hashSource();
}
