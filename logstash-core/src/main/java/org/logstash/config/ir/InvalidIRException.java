package org.logstash.config.ir;

/**
 * Created by andrewvc on 9/6/16.
 */
public class InvalidIRException extends Exception {
    private static final long serialVersionUID = 1L;

    public InvalidIRException(String s) {
        super(s);
    }

    public InvalidIRException(String s, Exception e) {
        super(s,e);
    }
}
