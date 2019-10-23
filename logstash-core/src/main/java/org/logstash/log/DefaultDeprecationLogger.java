package org.logstash.log;

import co.elastic.logstash.api.DeprecationLogger;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * Logger used to output deprecation warnings. It handles specific log4j loggers
 *
 * Inspired by ElasticSearch's org.elasticsearch.common.logging.DeprecationLogger
 * */
public class DefaultDeprecationLogger implements DeprecationLogger {

    private final Logger logger;

    /**
     * Creates a new deprecation logger based on the parent logger. Automatically
     * prefixes the logger name with "deprecation", if it starts with "org.logstash.",
     * it replaces "org.logstash" with "org.logstash.deprecation" to maintain
     * the "org.logstash" namespace.
     *
     * @param parentLogger parent logger to decorate
     */
    public DefaultDeprecationLogger(Logger parentLogger) {
        String name = parentLogger.getName();
        name = reworkLoggerName(name);
        this.logger = LogManager.getLogger(name);
    }

    DefaultDeprecationLogger(String pluginName) {
        String name = reworkLoggerName(pluginName);
        this.logger = LogManager.getLogger(name);
    }

    private String reworkLoggerName(String name) {
        if (name.startsWith("org.logstash")) {
            name = name.replace("org.logstash.", "org.logstash.deprecation.");
        } else {
            name = "deprecation." + name;
        }
        return name;
    }

    @Override
    public void deprecated(String message, Object... params) {
        logger.warn(message, params);
    }
}
