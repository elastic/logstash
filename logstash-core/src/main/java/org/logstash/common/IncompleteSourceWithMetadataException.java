package org.logstash.common;

import org.logstash.config.ir.InvalidIRException;

/**
 * Created by andrewvc on 6/12/17.
 */
public class IncompleteSourceWithMetadataException extends InvalidIRException {
    private static final long serialVersionUID = 456422097113787583L;

    public IncompleteSourceWithMetadataException(String message) {
        super(message);
    }
}
