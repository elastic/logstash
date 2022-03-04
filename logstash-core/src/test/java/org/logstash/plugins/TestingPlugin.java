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


package org.logstash.plugins;

import co.elastic.logstash.api.LogstashPlugin;
import co.elastic.logstash.api.Plugin;
import co.elastic.logstash.api.PluginConfigSpec;

import java.util.Collection;

import static org.logstash.plugins.TestingPlugin.TEST_PLUGIN_NAME;

@LogstashPlugin(name = TEST_PLUGIN_NAME)
public class TestingPlugin implements Plugin {

    static final String TEST_PLUGIN_NAME = "test_plugin";
    static final String ID = "TestingPluginId";

    private final Collection<PluginConfigSpec<?>> configSchema;

    TestingPlugin(Collection<PluginConfigSpec<?>> configSchema) {
        this.configSchema = configSchema;
    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        return configSchema;
    }

    @Override
    public String getId() {
        return ID;
    }
}
