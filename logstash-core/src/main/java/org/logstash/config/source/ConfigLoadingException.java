package org.logstash.config.source;

public class ConfigLoadingException extends Exception {

    private static final long serialVersionUID = 3043954726233024678L;

    public ConfigLoadingException(String message) {
        super(message);
    }

    public ConfigLoadingException(String message, Throwable cause) {
        super(message, cause);
    }
}
