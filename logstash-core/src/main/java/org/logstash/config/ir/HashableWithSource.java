package org.logstash.config.ir;

import org.logstash.common.Util;

/**
 * Created by andrewvc on 6/12/17.
 */
public interface HashableWithSource extends Hashable {
    @Override
    default String uniqueHash() {
        return Util.digest(hashSource());
    }
    String hashSource();
}
