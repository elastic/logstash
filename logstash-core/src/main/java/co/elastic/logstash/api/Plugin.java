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


package co.elastic.logstash.api;

import java.util.Collection;

/**
 * Base interface for Logstash Java plugins.
 */
public interface Plugin {

    /**
     * Provides all valid settings for this plugin as a collection of {@link PluginConfigSpec}. This will be used
     * to validate against the configuration settings that are supplied to this plugin at runtime.
     * @return Valid settings for this plugin.
     */
    Collection<PluginConfigSpec<?>> configSchema();

    /**
     * @return Name for this plugin. The default implementation uses the name specified in the {@link LogstashPlugin}
     * annotation, if available, and the class name otherwise.
     */
    default String getName() {
        LogstashPlugin annotation = getClass().getDeclaredAnnotation(LogstashPlugin.class);
        return (annotation != null && !annotation.name().equals(""))
                ? annotation.name()
                : getClass().getName();
    }

    /**
     * @return ID for the plugin. Input, filter, and output plugins must return the ID value that was supplied
     * to them at construction time. Codec plugins should generally create their own UUID at instantiation time
     * and supply that as their ID.
     */
    String getId();
}
