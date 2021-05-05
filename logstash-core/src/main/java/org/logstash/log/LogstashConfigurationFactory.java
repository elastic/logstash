/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


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

/**
 * Logstash configuration factory customization used to remove the routing appender from log4j configuration
 * if "separate_logs" settings is false.
 * */
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
