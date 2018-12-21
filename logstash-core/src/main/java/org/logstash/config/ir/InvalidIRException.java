package org.logstash.config.ir;

public class InvalidIRException extends Exception {
    public InvalidIRException(String s) {
        super(s);
    }

    public InvalidIRException(String s, Exception e) {
        super(s,e);
    }
}
