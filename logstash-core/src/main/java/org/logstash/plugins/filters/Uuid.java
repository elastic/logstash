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


package org.logstash.plugins.filters;

import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.Event;
import co.elastic.logstash.api.LogstashPlugin;
import co.elastic.logstash.api.PluginConfigSpec;
import co.elastic.logstash.api.PluginHelper;
import co.elastic.logstash.api.Filter;
import co.elastic.logstash.api.FilterMatchListener;

import java.util.Arrays;
import java.util.Collection;
import java.util.UUID;

/**
 * Java implementation of the "uuid" filter
 * */
@LogstashPlugin(name = "java_uuid")
public class Uuid implements Filter {

    public static final PluginConfigSpec<String> TARGET_CONFIG =
            PluginConfigSpec.requiredStringSetting("target");

    public static final PluginConfigSpec<Boolean> OVERWRITE_CONFIG =
            PluginConfigSpec.booleanSetting("overwrite", false);

    private String id;
    private String target;
    private boolean overwrite;

    /**
     * Required constructor.
     *
     * @param id            Plugin id
     * @param configuration Logstash Configuration
     * @param context       Logstash Context
     */
    public Uuid(final String id, final Configuration configuration, final Context context) {
        this.id = id;
        this.target = configuration.get(TARGET_CONFIG);
        this.overwrite = configuration.get(OVERWRITE_CONFIG);
    }

    @Override
    public Collection<Event> filter(Collection<Event> events, final FilterMatchListener filterMatchListener) {
        for (Event e : events) {
            if (overwrite || e.getField(target) == null) {
                e.setField(target, UUID.randomUUID().toString());
            }
            filterMatchListener.filterMatched(e);
        }
        return events;
    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        return PluginHelper.commonFilterSettings(Arrays.asList(TARGET_CONFIG, OVERWRITE_CONFIG));
    }

    @Override
    public String getId() {
        return id;
    }
}
