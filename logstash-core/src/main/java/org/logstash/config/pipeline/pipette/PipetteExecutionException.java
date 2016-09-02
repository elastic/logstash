package org.logstash.config.pipeline.pipette;


/**
 * Created by andrewvc on 9/30/16.
 */
public class PipetteExecutionException extends Exception {
    public PipetteExecutionException(String s) {
        super(s);
    }

    public PipetteExecutionException(String s, Exception e) {
        super(s,e);
    }
}