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
