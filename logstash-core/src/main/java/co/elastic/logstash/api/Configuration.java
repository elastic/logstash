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
 * Set of configuration settings for each plugin as read from the Logstash pipeline configuration.
 */
public interface Configuration {

    /**
     * Strongly-typed accessor for a configuration setting.
     * @param configSpec The setting specification for which to retrieve the setting value.
     * @param <T>        The type of the setting value to be retrieved.
     * @return           The value of the setting for the specified setting specification.
     */
    <T> T get(PluginConfigSpec<T> configSpec);

    /**
     * Weakly-typed accessor for a configuration setting.
     * @param configSpec The setting specification for which to retrieve the setting value.
     * @return           The weakly-typed value of the setting for the specified setting specification.
     */
    Object getRawValue(PluginConfigSpec<?> configSpec);

    /**
     * @param configSpec The setting specification for which to search.
     * @return           {@code true} if a value for the specified setting specification exists in
     * this {@link Configuration}.
     */
    boolean contains(PluginConfigSpec<?> configSpec);

    /**
     * @return Collection of the names of all settings in this configuration as reported by
     * {@link PluginConfigSpec#name()}.
     */
    Collection<String> allKeys();
}
