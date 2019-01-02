package org.logstash.config.ir;

public class InvalidIRException extends Exception {
    private static final long serialVersionUID = 1L;

    public InvalidIRException(String s) {
        super(s);
    }

    public InvalidIRException(String s, Exception e) {
        super(s,e);
    }
}
