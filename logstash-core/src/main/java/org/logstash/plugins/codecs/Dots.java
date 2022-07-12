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


package org.logstash.plugins.codecs;

import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.Event;
import co.elastic.logstash.api.LogstashPlugin;
import co.elastic.logstash.api.PluginConfigSpec;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.util.Collection;
import java.util.Collections;
import java.util.Map;
import java.util.UUID;
import java.util.function.Consumer;

/**
 * Java implementation of the "dots" codec
 * */
@LogstashPlugin(name = "jdots")
public class Dots implements Codec {

    private final String id;

    public Dots(final String id, final Configuration configuration, final Context context) {
        this((id != null && !id.isEmpty()) ? id : UUID.randomUUID().toString());
    }

    public Dots(final Configuration configuration, final Context context) {
        this(UUID.randomUUID().toString());
    }

    private Dots(String id) {
        this.id = id;
    }

    @Override
    public void decode(ByteBuffer buffer, Consumer<Map<String, Object>> eventConsumer) {
        throw new UnsupportedOperationException("Cannot decode with the jdots codec");
    }

    @Override
    public void flush(ByteBuffer buffer, Consumer<Map<String, Object>> eventConsumer) {
    }

    @Override
    public void encode(Event event, OutputStream out) throws IOException {
        out.write('.');
        out.flush();
    }

    @Override
    public Codec cloneCodec() {
        return new Dots(UUID.randomUUID().toString());
    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        return Collections.emptyList();
    }

    @Override
    public String getId() {
        return id;
    }
}
