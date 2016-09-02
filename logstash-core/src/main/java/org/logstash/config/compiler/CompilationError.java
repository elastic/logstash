package org.logstash.config.compiler;

import org.logstash.config.ir.InvalidIRException;

/**
 * Created by andrewvc on 9/22/16.
 */
public class CompilationError extends Exception {
    public CompilationError(String s, InvalidIRException e) {
        super(s,e);
    }

    public CompilationError(String s) {
        super(s);
    }
}
