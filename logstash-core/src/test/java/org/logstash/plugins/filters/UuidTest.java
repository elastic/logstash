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
import co.elastic.logstash.api.Event;
import co.elastic.logstash.api.FilterMatchListener;
import org.junit.Assert;
import org.junit.Test;
import org.logstash.plugins.ConfigurationImpl;
import org.logstash.plugins.ContextImpl;
import org.logstash.plugins.PluginUtil;

import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

public class UuidTest {

    private static final String ID = "uuid_test_id";
    private static final NoopFilterMatchListener NO_OP_MATCH_LISTENER = new NoopFilterMatchListener();

    @Test
    public void testUuidWithoutRequiredConfigThrows() {
        try {
            Configuration config = new ConfigurationImpl(Collections.emptyMap());
            Uuid uuid = new Uuid(ID, config, new ContextImpl(null, null));
            PluginUtil.validateConfig(uuid, config);
            Assert.fail("java-uuid filter without required config should have thrown exception");
        } catch (IllegalStateException ex) {
            Assert.assertTrue(ex.getMessage().contains("Config errors found for plugin 'java_uuid'"));
        } catch (Exception ex2) {
            Assert.fail("Unexpected exception for java-uuid filter without required config");
        }
    }

    @Test
    public void testUuidWithoutOverwrite() {
        String targetField = "target_field";
        String originalValue = "originalValue";
        Map<String, Object> rawConfig = new HashMap<>();
        rawConfig.put(Uuid.TARGET_CONFIG.name(), targetField);
        Configuration config = new ConfigurationImpl(rawConfig);
        Uuid uuid = new Uuid(ID, config, new ContextImpl(null, null));
        PluginUtil.validateConfig(uuid, config);

        org.logstash.Event e = new org.logstash.Event();
        e.setField(targetField, originalValue);
        Collection<Event> filteredEvents = uuid.filter(Collections.singletonList(e), NO_OP_MATCH_LISTENER);

        Assert.assertEquals(1, filteredEvents.size());
        Event finalEvent = filteredEvents.stream().findFirst().orElse(null);
        Assert.assertNotNull(finalEvent);
        Assert.assertEquals(originalValue, finalEvent.getField(targetField));
    }

    @Test
    public void testUuidWithOverwrite() {
        String targetField = "target_field";
        String originalValue = "originalValue";
        Map<String, Object> rawConfig = new HashMap<>();
        rawConfig.put(Uuid.TARGET_CONFIG.name(), targetField);
        rawConfig.put(Uuid.OVERWRITE_CONFIG.name(), true);
        Configuration config = new ConfigurationImpl(rawConfig);
        Uuid uuid = new Uuid(ID, config, new ContextImpl(null, null));
        PluginUtil.validateConfig(uuid, config);

        org.logstash.Event e = new org.logstash.Event();
        e.setField(targetField, originalValue);
        Collection<Event> filteredEvents = uuid.filter(Collections.singletonList(e), NO_OP_MATCH_LISTENER);

        Assert.assertEquals(1, filteredEvents.size());
        Event finalEvent = filteredEvents.stream().findFirst().orElse(null);
        Assert.assertNotNull(finalEvent);
        Assert.assertNotEquals(originalValue, finalEvent.getField(targetField));
        Assert.assertTrue(((String)finalEvent.getField(targetField)).matches("\\b[0-9a-f]{8}\\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\\b[0-9a-f]{12}\\b"));
    }

    private static class NoopFilterMatchListener implements FilterMatchListener {

        @Override
        public void filterMatched(Event e) {

        }
    }
}
