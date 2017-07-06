package org.logstash.log;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.spi.LoggerContext;
import org.apache.logging.log4j.spi.LoggerContextFactory;

import java.net.URI;

/**
 * Log4j context factory to enable injection of a pre-established context. This may be used in conjunction with
 * {@link LogManager#setFactory(LoggerContextFactory)} to ensure that the injected pre-established context is used by the {@link LogManager}
 */
public class LogstashLoggerContextFactory implements LoggerContextFactory {

    private final LoggerContext context;

    /**
     * Constructor
     *
     * @param context The {@link LoggerContext} that this factory will ALWAYS return.
     */
    public LogstashLoggerContextFactory(LoggerContext context) {
        this.context = context;
    }

    @Override
    public LoggerContext getContext(String fqcn, ClassLoader loader, Object externalContext, boolean currentContext) {
        return context;
    }

    @Override
    public LoggerContext getContext(String fqcn, ClassLoader loader, Object externalContext, boolean currentContext,
                                    URI configLocation, String name) {
        return context;
    }

    @Override
    public void removeContext(LoggerContext context) {
        //do nothing
    }
}
