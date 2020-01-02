package org.logstash.log;

import org.apache.logging.log4j.core.LoggerContext;
import org.apache.logging.log4j.core.config.ConfigurationException;
import org.apache.logging.log4j.core.config.ConfigurationFactory;
import org.apache.logging.log4j.core.config.ConfigurationSource;
import org.apache.logging.log4j.core.config.Order;
import org.apache.logging.log4j.core.config.plugins.Plugin;
import org.apache.logging.log4j.core.config.properties.PropertiesConfiguration;
import org.apache.logging.log4j.core.config.properties.PropertiesConfigurationBuilder;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

@Plugin(name = "LogstashConfigurationFactory", category = ConfigurationFactory.CATEGORY)
@Order(9)
public class LogstashConfigurationFactory extends ConfigurationFactory {

    static final String PIPELINE_ROUTING_APPENDER_NAME = "pipeline_routing_appender";
    public static final String PIPELINE_SEPARATE_LOGS = "ls.pipeline.separate_logs";

    @Override
    protected String[] getSupportedTypes() {
        return new String[] {".properties"};
    }

    @Override
    public PropertiesConfiguration getConfiguration(final LoggerContext loggerContext, final ConfigurationSource source) {
        final Properties properties = new Properties();
        try (final InputStream configStream = source.getInputStream()) {
            properties.load(configStream);
        } catch (final IOException ioe) {
            throw new ConfigurationException("Unable to load " + source.toString(), ioe);
        }
        PropertiesConfiguration propertiesConfiguration = new PropertiesConfigurationBuilder()
                .setConfigurationSource(source)
                .setRootProperties(properties)
                .setLoggerContext(loggerContext)
                .build();

        if (System.getProperty(PIPELINE_SEPARATE_LOGS, "false").equals("false")) {
            // force init to avoid overwrite of appenders section
            propertiesConfiguration.initialize();
            propertiesConfiguration.removeAppender(PIPELINE_ROUTING_APPENDER_NAME);
        }

        return propertiesConfiguration;
    }
}
