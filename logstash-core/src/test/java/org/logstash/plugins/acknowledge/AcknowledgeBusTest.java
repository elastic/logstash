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

package org.logstash.plugins.acknowledge;

import org.junit.Before;
import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;

import org.logstash.Event;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyEventExtLibrary;

import co.elastic.logstash.api.AcknowledgablePlugin;
import co.elastic.logstash.api.AcknowledgeBus;
import co.elastic.logstash.api.AcknowledgeToken;
import co.elastic.logstash.api.AcknowledgeTokenFactory;
import co.elastic.logstash.api.PluginConfigSpec;

public class AcknowledgeBusTest {

    AcknowledgeBus bus;
    TestAcknowledgePlugin plugin;
    static String pluginId = "test_acknowledge_input";

    @Before
    public void setup() {
        bus = new org.logstash.plugins.acknowledge.AcknowledgeBus();
        plugin = new TestAcknowledgePlugin(pluginId);
    }

    @Test
    public void registerUnregister() throws InterruptedException {
        Object factory = bus.registerPlugin(plugin);
        assertThat(factory).isInstanceOf(AcknowledgeTokenFactory.class);

        assertThat(bus.unregisterPlugin(plugin)).isTrue();
        assertThat(bus.unregisterPlugin(plugin)).isFalse();
    }

    @Test
    public void registerAndReceiveAcknowledge() throws InterruptedException {
        AcknowledgeTokenFactory factory = bus.registerPlugin(plugin);
        Collection<JrubyEventExtLibrary.RubyEvent> events = Arrays.asList(
            rubyEvent(),
            rubyEvent(factory.generateToken("1")),
            rubyEvent(),
            rubyEvent(factory.generateToken("2")),
            rubyEvent()
        );
        bus.acknowledgeEvents(events);
        assertThat(plugin.acknowledged.size()).isEqualTo(2);
        assertThat(plugin.acknowledged).contains("2", "1");
        assertThat(plugin.cloned.size()).isEqualTo(0);
    }

    @Test
    public void registerAndReceiveCloned() throws InterruptedException {
        AcknowledgeTokenFactory factory = bus.registerPlugin(plugin);
        Collection<JrubyEventExtLibrary.RubyEvent> events = Arrays.asList(
            rubyEvent(),
            rubyEvent(factory.generateToken("1")),
            rubyEvent(),
            rubyEvent(factory.generateToken("2")),
            rubyEvent()
        );
        bus.notifyClonedEvents(events);
        assertThat(plugin.cloned.size()).isEqualTo(2);
        assertThat(plugin.cloned).contains("2", "1");
        assertThat(plugin.acknowledged.size()).isEqualTo(0);
    }

    @Test
    public void registerUnregisterNoReceiveCloned() throws InterruptedException {
        AcknowledgeTokenFactory factory = bus.registerPlugin(plugin);
        Collection<JrubyEventExtLibrary.RubyEvent> events = Arrays.asList(
            rubyEvent(),
            rubyEvent(factory.generateToken("1")),
            rubyEvent(),
            rubyEvent(factory.generateToken("2")),
            rubyEvent()
        );
        assertThat(bus.unregisterPlugin(plugin)).isTrue();

        bus.notifyClonedEvents(events);
        assertThat(plugin.cloned.size()).isEqualTo(0);
        assertThat(plugin.acknowledged.size()).isEqualTo(0);
    }

    @Test
    public void registerUnregisterNoReceiveAcknowledged() throws InterruptedException {
        AcknowledgeTokenFactory factory = bus.registerPlugin(plugin);
        Collection<JrubyEventExtLibrary.RubyEvent> events = Arrays.asList(
            rubyEvent(),
            rubyEvent(factory.generateToken("1")),
            rubyEvent(),
            rubyEvent(factory.generateToken("2")),
            rubyEvent()
        );
        assertThat(bus.unregisterPlugin(plugin)).isTrue();

        bus.acknowledgeEvents(events);
        assertThat(plugin.cloned.size()).isEqualTo(0);
        assertThat(plugin.acknowledged.size()).isEqualTo(0);
    }

    @Test
    public void registerDoubleIdReturnsNull() throws InterruptedException {
        TestAcknowledgePlugin plugin2 = new TestAcknowledgePlugin(pluginId);
        Object factory1 = bus.registerPlugin(plugin);
        Object factory2 = bus.registerPlugin(plugin2);

        assertThat(factory1).isNotNull();
        assertThat(factory1).isInstanceOf(AcknowledgeTokenFactory.class);
        assertThat(factory2).isNull();
    }

    @Test
    public void registerMultipleReceiveBySingle() throws InterruptedException {
        TestAcknowledgePlugin plugin2 = new TestAcknowledgePlugin("plugin2");
        AcknowledgeTokenFactory factory1 = bus.registerPlugin(plugin);
        AcknowledgeTokenFactory factory2 = bus.registerPlugin(plugin2);
        Collection<JrubyEventExtLibrary.RubyEvent> events = Arrays.asList(
            rubyEvent(),
            rubyEvent(factory1.generateToken("1")),
            rubyEvent(factory2.generateToken("1")),
            rubyEvent(factory1.generateToken("2")),
            rubyEvent(factory1.generateToken("3")),
            rubyEvent(factory2.generateToken("4"))
        );
        bus.acknowledgeEvents(events);
        bus.notifyClonedEvents(events);
        assertThat(plugin.cloned.size()).isEqualTo(3);
        assertThat(plugin.cloned).contains("2", "3", "1");
        assertThat(plugin.acknowledged.size()).isEqualTo(3);
        assertThat(plugin.acknowledged).contains("2", "3", "1");
        assertThat(plugin2.cloned.size()).isEqualTo(2);
        assertThat(plugin2.cloned).contains("4", "1");
        assertThat(plugin2.acknowledged.size()).isEqualTo(2);
        assertThat(plugin2.acknowledged).contains("4", "1");
    }

    @Test
    public void receiveAcknowledgeUnknownPlugin() throws InterruptedException {
        bus.registerPlugin(plugin);
        AcknowledgeToken token = new AcknowledgeToken(){
            @Override
            public String getPluginId() {
                return "Non_existing_plugin";
            }

            @Override
            public String getAcknowledgeId() {
                return "dummyId";
            }
        };
        Collection<JrubyEventExtLibrary.RubyEvent> events = Arrays.asList(
            rubyEvent(token),
            rubyEvent()
        );

        bus.acknowledgeEvents(events);
        bus.notifyClonedEvents(events);

        assertThat(plugin.cloned.size()).isEqualTo(0);
        assertThat(plugin.acknowledged.size()).isEqualTo(0);
    }

    private JrubyEventExtLibrary.RubyEvent rubyEvent() {
        return JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY);
    }
    private JrubyEventExtLibrary.RubyEvent rubyEvent(AcknowledgeToken token) {
        return JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, new Event(token));
    }

    static class TestAcknowledgePlugin implements AcknowledgablePlugin {
        public List<String> acknowledged = new ArrayList<>();
        public List<String> cloned = new ArrayList<>();

        private String id;

        TestAcknowledgePlugin(String id){
            this.id = id;
        }

        @Override
        public Collection<PluginConfigSpec<?>> configSchema() {
            return null;
        }

        @Override
        public String getId() {
            return id;
        }

        @Override
        public boolean acknowledge(String acknowledgeId) {
            return acknowledged.add(acknowledgeId);
        }

        @Override
        public boolean notifyCloned(String acknowledgeId) {
            return cloned.add(acknowledgeId);
        }
    }

}