package org.logstash.common;

import org.logstash.config.ir.InvalidIRException;

/**
 * Created by andrewvc on 6/12/17.
 */
public class IncompleteSourceWithMetadataException extends InvalidIRException {
    public IncompleteSourceWithMetadataException(String message) {
        super(message);
    }
}
