package org.logstash.config.ir;

import org.logstash.common.Util;

/**
 * Created by andrewvc on 12/23/16.
 */
public interface Hashable {
    String hashSource();

    default String uniqueHash() {
        return Util.digest(this.hashSource());
    }
}
